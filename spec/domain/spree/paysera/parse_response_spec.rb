# frozen_string_literal: true

RSpec.describe Spree::Paysera::ParseResponse do
  subject { described_class.for(payment_method, response) }

  let(:payment_method) { create(:paysera_gateway) }
  let(:response) do
    {
      data: data,
      ss1: Digest::MD5.hexdigest(data + payment_method.preferred_sign_key),
      ss2: 'ss2'
    }
  end
  let(:data) { Base64.encode64(CGI.unescape('orderid=R4131&amount=9400')) }

  before do
    allow_any_instance_of(described_class).to receive_messages valid_ss2?: true
  end

  describe '.for' do
    it 'decodes the data' do
      expect(subject).to include(
        amount: '9400',
        orderid: 'R4131'
      )
    end
  end
end
