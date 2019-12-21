# frozen_string_literal: true

require 'cgi'
require 'digest/md5'

class Spree::Paysera::BuildUrl
  attr_reader :payment_method, :options

  def self.for(payment_method, options)
    new(payment_method, options).run
  end

  def initialize(payment_method, options)
    @payment_method = payment_method
    @options = options
  end

  def run
    provider_url + make_query(
      data: assertion,
      sign: sign_request(assertion, payment_method.preferred_sign_key)
    )
  end

  private

  def assertion
    @assertion ||= encode_string(make_query(options))
  end

  def make_query(data)
    data.collect do |key, value|
      "#{CGI.escape(key.to_s)}=#{CGI.escape(value.to_s)}"
    end.compact.sort!.join('&')
  end

  def encode_string(string)
    Base64.encode64(string).gsub("\n", '').gsub('/', '_').gsub('+', '-')
  end

  def sign_request(query, password)
    Digest::MD5.hexdigest(query + password)
  end

  def provider_url
    if payment_method.preferred_service_url.nil?
      return 'https://www.paysera.lt/pay/?'
    end

    payment_method.preferred_service_url
  end
end
