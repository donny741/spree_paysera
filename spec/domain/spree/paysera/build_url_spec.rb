# frozen_string_literal: true

RSpec.describe Spree::Paysera::BuildUrl do
  subject { described_class.for(payment_method, options) }

  let(:payment_method) { create(:paysera_gateway) }
  let(:options) { build(:paysera_form).attributes }

  describe '.for' do
    it 'builds request params hash and signs the request' do
      params = CGI.parse(URI.parse(subject).query)
      data = params['data'][0]
      ss1 = params ['sign'][0]
      attributes = CGI.parse(Base64.decode64(data)).each.with_object({}) do |(key, value), result|
        result[key] = value[0]
      end.symbolize_keys

      expect(attributes).to eq(options)
      expect(
        Digest::MD5.hexdigest(data + payment_method.preferred_sign_key)
      ).to eq(ss1)
    end
  end
end
