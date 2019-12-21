# frozen_string_literal: true

require 'base64'
require 'cgi'
require 'digest/md5'
require 'net/http'
require 'uri'
require 'openssl'
require 'open-uri'
module Spree
  class PayseraController < StoreController
    protect_from_forgery only: :index

    include Spree::Paysera::ErrorHandler

    def index
      form = Spree::Paysera::BuildForm.for(payment_method, current_order)
      url = Spree::Paysera::BuildUrl.for(payment_method, form.attributes)

      redirect_to url
    end

    def callback
      Spree::LogEntry.create(
        source: payment_method,
        details: params.to_yaml
      )
      response = Spree::Paysera::ParseResponse.for(payment_method, params)

      if response[:projectid] != payment_method.preferred_project_id.to_s
        raise Spree::Paysera::Error, 'project id does not match'
      end

      order = Spree::Order.find_by!(number: response[:orderid])

      money = order.total * 100
      if response[:payamount].to_i >= money.to_i
        if response[:payamount].to_i > money.to_i
          payment = order.payments.create!(
            source_type: 'Spree::Gateway::Paysera',
            amount: response[:payamount].to_d / 100,
            payment_method: payment_method
          )
          payment.complete
          order.next

          render plain: 'OK payment amount is greater than order total'
        else
          payment = order.payments.create!(
            source_type: 'Spree::Gateway::Paysera',
            amount: response[:payamount].to_d / 100,
            payment_method: payment_method
          )
          payment.complete
          order.next

          render plain: 'OK'
        end
      else
        raise Spree::Paysera::Error, 'bad order amount'
      end
    end

    def confirm
      response = Spree::Paysera::ParseResponse.for(payment_method, params)

      order = Spree::Order.find_by(number: response[:orderid])

      if %w[paid credit_owed].include?(order.payment_state)
        flash.notice = Spree.t(:order_processed_successfully)
      else
        flash.alert = Spree.t(:payment_processing_failed)
      end
    rescue StandardError
      flash.alert = Spree.t(:payment_processing_failed)
    ensure
      redirect_to account_path
    end

    def cancel
      flash.notice = Spree.t(:order_canceled)
      redirect_to products_path
    end

    private

    def payment_method
      @payment_method ||= Spree::Gateway::Paysera.find(params[:payment_method_id])
    end
  end
end
