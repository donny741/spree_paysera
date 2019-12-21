# frozen_string_literal: true

RSpec.describe Spree::Paysera::BuildForm do
  subject { described_class.for(payment_method, order) }
  let(:order) { OrderWalkthrough.up_to(:payment) }
  let(:payment_method) { create(:paysera_gateway) }

  describe '.for' do
    let(:request_params) do
      {
        projectid: payment_method.preferred_project_id,
        orderid: order.number,
        callbackurl: payment_method.preferred_domain_name.chomp('/').gsub("\n", '') + "/paysera/#{payment_method.id}/callback".gsub("\n", ''),
        accepturl: payment_method.preferred_domain_name.chomp('/').gsub("\n", '') + "/paysera/#{payment_method.id}/confirm".gsub("\n", ''),
        cancelurl: payment_method.preferred_domain_name.chomp('/').gsub("\n", '') + "/paysera/#{payment_method.id}/cancel".gsub("\n", ''),
        amount: (order.total * 100).to_i,
        currency: order.currency,
        test: payment_method.preferred_test_mode ? 1 : 0,
        paytext: payment_method.preferred_message_text.present? ? payment_method.preferred_message_text : 'Payment',
        p_firstname: order.bill_address.firstname,
        p_lastname: order.bill_address.lastname,
        p_street: order.bill_address.address1 + ' ' + order.bill_address.address2,
        p_city: order.bill_address.city,
        p_zip: order.bill_address.zipcode
      }
    end
    it 'builds request params hash' do
      expect(subject).to have_attributes(request_params)
    end
  end
end
