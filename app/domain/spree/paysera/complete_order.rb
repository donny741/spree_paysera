# frozen_string_literal: true

class Spree::Paysera::CompleteOrder
  attr_reader :order, :payment_method, :order_total, :payamount

  def self.for(order, payment_method, params)
    new(order, payment_method, params).run
  end

  def initialize(order, payment_method, params)
    @order = order
    @payment_method = payment_method
    @order_total = order.total.to_money
    @payamount = params[:payamount].to_money / 100
  end

  def run
    return if order.paid?

    check_payammount!
    complete_order
  end

  private

  def check_payammount!
    return if payamount >= order_total

    raise Spree::Paysera::Error, 'bad order amount'
  end

  def complete_order
    payment = order.payments.create!(
      source_type: 'Spree::Gateway::Paysera',
      amount: payamount.to_d,
      payment_method: payment_method
    )
    payment.complete
    order.next
  end
end
