# frozen_string_literal: true

class Spree::Paysera::Request::Build
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

    @result
  end

  private

  def add_gateway_details
    @result.merge!(
      orderid: order.number,
      callbackurl: paysera_callback_url(payment_method.id, host: payment_method.preferred_domain_name),
      accepturl: paysera_confirm_url(payment_method.id, host: payment_method.preferred_domain_name),
      cancelurl: paysera_cancel_url(payment_method.id, host: payment_method.preferred_domain_name),
      paytext: payment_method.preferred_message_text || 'Payment',
      test: payment_method.preferred_test_mode ? 1 : 0
    )
  end

  def add_order_details
    @result.merge!(
      amount: order.total.to_money.cents,
      currency: order.currency,
      p_firstname: order.bill_address.firstname,
      p_lastname: order.bill_address.lastname,
      p_street: order.bill_address.address1 + ' ' + order.bill_address.address2,
      p_city: order.bill_address.city,
      p_zip: order.bill_address.zipcode
    )
  end
end
