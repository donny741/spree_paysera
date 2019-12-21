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
      raise Spree::Paysera::Error if params[:data].nil?

      Spree::LogEntry.create(
        source: payment_method,
        details: params.to_yaml
      )
      response = parse_response

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
      response = parse_response

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

    def data
      @data ||= params.require(:data)
    end

    def ss1
      @ss1 ||= params.require(:ss1)
    end

    def ss2
      @ss2 ||= params.require(:ss2)
    end

    PUBLIC_KEY = 'http://www.paysera.com/download/public.key'

    def parse_response
      projectid ||= payment_method.preferred_project_id
      raise Spree::Paysera::Error, 'Error: projectid not found' if projectid.nil?

      sign_password ||= payment_method.preferred_sign_key
      raise Spree::Paysera::Error, 'Error: sign_password not found' if sign_password.nil?

      unless valid_ss1? data, ss1, sign_password
        raise Spree::Paysera::Error, 'ss1 verification failed'
      end
      unless valid_ss2? data, ss2
        raise Spree::Paysera::Error, 'ss2 verification failed'
      end

      convert_to_hash decode_string(data)
    end

    def convert_to_hash(query)
      Hash[query.split('&').collect do |s|
             a = s.split('=')
             [unescape_string(a[0]).to_sym, unescape_string(a[1])]
           end]
    end

    def get_public_key
      OpenSSL::X509::Certificate.new(open(PUBLIC_KEY).read).public_key
    end

    def decode_string(string)
      Base64.decode64 string.gsub('-', '+').gsub('_', '/').gsub("\n", '')
    end

    def valid_ss1?(data, ss1, sign_password)
      Digest::MD5.hexdigest(CGI.unescape(data) + sign_password) == ss1
    end

    def valid_ss2?(data, ss2)
      public_key = get_public_key
      ss2        = decode_string(unescape_string(ss2))
      data       = unescape_string data

      public_key.verify(OpenSSL::Digest::SHA1.new, ss2, data)
    end

    def unescape_string(string)
      CGI.unescape string.to_s
    end
  end
end
