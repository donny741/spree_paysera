# frozen_string_literal: true

class Spree::Paysera::ParseResponse
  attr_reader :payment_method, :data, :ss1, :ss2

  PUBLIC_KEY = 'http://www.paysera.com/download/public.key'

  def self.for(payment_method, response)
    new(payment_method, response).run
  end

  def initialize(payment_method, response)
    @payment_method = payment_method
    @data = response[:data]
    @ss1 = response[:ss1]
    @ss2 = response[:ss2]
  end

  def run
    raise Spree::Paysera::Error, 'sign_password not found' if payment_method.preferred_sign_key.nil?
    raise Spree::Paysera::Error, 'projectid not found' if payment_method.preferred_project_id.nil?
    raise Spree::Paysera::Error, 'invalid ss1' unless valid_ss1?
    raise Spree::Paysera::Error, 'invalid ss2' unless valid_ss2?

    convert_to_hash decode_string(data)
  end

  private

  def convert_to_hash(query)
    Hash[query.split('&').collect do |s|
           a = s.split('=')
           [unescape_string(a[0]).to_sym, unescape_string(a[1])]
         end]
  end

  def decode_string(string)
    Base64.decode64 string.gsub('-', '+').gsub('_', '/').gsub("\n", '')
  end

  def valid_ss1?
    sign_password = payment_method.preferred_sign_key
    Digest::MD5.hexdigest(CGI.unescape(data) + sign_password) == ss1
  end

  def valid_ss2?
    ss2        = decode_string(unescape_string(ss2))
    data       = unescape_string(data)

    public_key.verify(OpenSSL::Digest::SHA1.new, ss2, data)
  end

  def public_key
    OpenSSL::X509::Certificate.new(open(PUBLIC_KEY).read).public_key
  end

  def unescape_string(string)
    CGI.unescape(string)
  end
end
