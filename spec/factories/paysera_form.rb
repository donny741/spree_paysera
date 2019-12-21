# frozen_string_literal: true

FactoryBot.define do
  factory :paysera_form, class: Spree::PayseraForm do
    projectid { '12' }
    version { '1.6' }
    orderid { 'R00001' }
    accepturl { 'https://dummy.url/accept' }
    cancelurl { 'https://dummy.url/cancel' }
    callbackurl { 'https://dummy.url/callback' }
    amount { '2000' }
    currency { 'EUR' }
  end
end
