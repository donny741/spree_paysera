# frozen_string_literal: true

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
      raise Spree::Paysera::Error, 'wrong project id' if response[:projectid] != payment_method.preferred_project_id.to_s

      order = Spree::Order.find_by!(number: response[:orderid])

      Spree::Paysera::CompleteOrder.for(order, payment_method, response)
      render plain: 'OK'
    end

    def confirm
      response = Spree::Paysera::ParseResponse.for(payment_method, params)
      order = Spree::Order.find_by(number: response[:orderid])

      if order.paid?
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
