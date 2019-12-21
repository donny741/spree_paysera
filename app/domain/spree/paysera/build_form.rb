# frozen_string_literal: true

class Spree::Paysera::BuildForm
  include Spree::Core::Engine.routes.url_helpers

  attr_reader :payment_method, :order

  def self.for(payment_method, order)
    new(payment_method, order).run
  end

  def initialize(payment_method, order)
    @payment_method = payment_method
    @order = order
  end

  def run
    @result = {}

    add_gateway_details
    add_order_details

    form = Spree::PayseraForm.new(@result)
    raise Spree::Paysera::Error, 'Params are not valid' unless form.valid?

    form
  end

  private

  def add_gateway_details
    host = payment_method.preferred_domain_name.chomp('/')

    @result.merge!(
      version: payment_method.preferred_api_version,
      projectid: payment_method.preferred_project_id,
      callbackurl: paysera_callback_url(payment_method.id, host: host),
      accepturl: paysera_confirm_url(payment_method.id, host: host),
      cancelurl: paysera_cancel_url(payment_method.id, host: host),
      paytext: payment_method.preferred_message_text || 'Payment',
      test: payment_method.preferred_test_mode ? 1 : 0
    )
  end

  def add_order_details
    address = order.bill_address
    @result.merge!(
      orderid: order.number,
      amount: order.total.to_money.cents,
      currency: order.currency,
      p_firstname: address.firstname,
      p_lastname: address.lastname,
      p_street: address.address1 + ' ' + address.address2,
      p_city: address.city,
      p_zip: address.zipcode
    )
  end
end
