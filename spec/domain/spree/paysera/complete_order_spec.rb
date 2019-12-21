# frozen_string_literal: true

RSpec.describe Spree::Paysera::CompleteOrder do
  subject { described_class.for(order, payment_method, params) }

  let(:order) { OrderWalkthrough.up_to(:payment) }
  let(:payment_method) { create(:paysera_gateway) }
  let(:params) do
    {
      payamount: payamount
    }
  end

  describe '.for' do
    let(:payamount) { (order.total * 100).to_s }

    it 'completes the order' do
      expect { subject }.to change(order.payments, :count).by 1
      expect(subject).to be_truthy
      expect(order.reload).to have_attributes(
        payment_state: 'paid'
      )
    end

    context 'when payamount is greater that order total' do
      let(:payamount) { (order.total * 100 + 1).to_s }

      it 'completes the order and gives credit' do
        expect { subject }.to change(order.payments, :count).by 1
        expect(subject).to be_truthy
        expect(order.reload).to have_attributes(
          payment_state: 'credit_owed'
        )
      end
    end

    context 'when payamount is less that order total' do
      let(:payamount) { (order.total * 100 - 1).to_s }

      it 'completes the order and gives credit' do
        expect { subject }.to raise_error Spree::Paysera::Error
        expect(order.reload.payments.count).to eq(0)
      end
    end

    context 'when order completed' do
      let(:order) do
        order = OrderWalkthrough.up_to(:payment)
        order.update payment_state: 'credit_owed'
        order
      end

      it 'does nothing' do
        expect { subject }.not_to change(order.payments, :count)
        expect { subject }.not_to change(order, :payment_state)
      end
    end
  end
end
