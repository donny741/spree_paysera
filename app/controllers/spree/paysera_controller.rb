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

    def index
      form = Spree::Paysera::BuildForm.for(payment_method, current_order)
      url = Spree::Paysera::BuildUrl.for(payment_method, form.attributes)

      redirect_to url
    end

    def callback
      if params[:data].nil?
        begin
          redirect_to products_path
        end
        return
      end

      Spree::LogEntry.create(
        source: payment_method,
        details: params.to_yaml
      )
      response = parse(params)

      # not working
      if response[:projectid].to_i != payment_method.preferred_project_id
        render plain: 'Error: project id does not match'
        return
      end

      order = Spree::Order.find_by(number: response[:orderid])
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

          if order.payment_state == 'paid'
            render plain: 'OK payment amount is greater than order total'
            nil
          else
            render plain: 'Error processing payment'
            nil
          end
        else
          payment = order.payments.create!(
            source_type: 'Spree::Gateway::Paysera',
            amount: response[:payamount].to_d / 100,
            payment_method: payment_method
          )
          payment.complete
          order.next

          if order.payment_state == 'paid'
            render plain: 'OK'
            nil
          else
            render plain: 'Error processing payment'
            nil
          end
        end
      else
        render plain: 'Error: bad order amount'
        nil
      end
    end

    def confirm
      payment_method = Spree::PaymentMethod.find_by(id: params[:payment_method_id])
      if payment_method.type != 'Spree::Gateway::Paysera'
        raise send_error('invalid payment method')
      end

      if params[:data].nil?
        begin
          redirect_to products_path
        end
        return
      end
      response = parse(params)
      if response[:projectid].to_i != payment_method.preferred_project_id
        raise send_error("'projectid' mismatch")
      end

      order = Spree::Order.find_by(number: response[:orderid])

      if order.payment_state != 'paid'
        flash.alert = Spree.t(:payment_processing_failed)
        begin
          redirect_to cart_path
        end
        return
      end

      flash.notice = Spree.t(:order_processed_successfully)
      begin
        # check if exists
        redirect_to account_path
      end
      nil
    end

    def cancel
      flash.notice = Spree.t(:order_canceled)
      begin
        redirect_to products_path
      end
    end

    private

    def payment_method
      @payment_method ||= Spree::Gateway::Paysera.find(params[:payment_method_id])
    end

    PUBLIC_KEY = 'http://www.paysera.com/download/public.key'

    def parse(query)
      payment_method = Spree::PaymentMethod.find_by(id: params[:payment_method_id])
      if payment_method.type != 'Spree::Gateway::Paysera'
        raise send_error('invalid payment method')
      end

      render plain: 'Error: data not found' if query[:data].nil?
      render plain: 'Error: ss1 not found' if query[:ss1].nil?
      render plain: 'Error: ss2 not found' if query[:ss2].nil?

      projectid ||= payment_method.preferred_project_id
      render plain: 'Error: projectid not found' if projectid.nil?

      sign_password ||= payment_method.preferred_sign_key
      render plain: 'Error: sign_password not found' if sign_password.nil?

      unless valid_ss1? query[:data], query[:ss1], sign_password
        render plain: 'ss1 verification failed'
      end
      unless valid_ss2? query[:data], query[:ss2]
        render plain: 'ss2 verification failed'
      end

      convert_to_hash decode_string(query[:data])
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

    def make_query(data)
      data.collect do |key, value|
        "#{CGI.escape(key.to_s)}=#{CGI.escape(value.to_s)}"
      end.compact.sort! * '&'
    end

    def sign_request(query, password)
      Digest::MD5.hexdigest(query + password)
    end

    def encode_string(string)
      Base64.encode64(string).gsub("\n", '').gsub('/', '_').gsub('+', '-')
    end
  end
end
