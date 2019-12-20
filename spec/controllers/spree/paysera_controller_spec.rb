# frozen_string_literal: true

RSpec.describe Spree::PayseraController, type: :controller do
  let(:user) { create(:user) }
  let(:order) { OrderWalkthrough.up_to(:payment) }
  let(:payment_method) { create(:paysera_gateway) }

  before do
    allow(controller).to receive_messages try_spree_current_user: user
    allow(controller).to receive_messages spree_current_user: user
    allow(controller).to receive_messages current_order: order
  end

  describe '#index' do
    subject { get :index, params: params }
    let(:params) do
      { payment_method_id: payment_method.id }
    end

    it 'redirects to paysera' do
      expect(subject.redirect_url).to start_with 'https://www.paysera.lt/pay/?data='
    end
  end

  describe '#callback' do
    subject { get :callback, params: params }

    let(:params) do
      {
        payment_method_id: payment_method.id,
        data: 'data',
        ss1: 'ss1',
        ss2: 'ss2'
      }
    end

    before do
      allow(controller).to receive(:parse).and_return(
        projectid: payment_method.preferred_project_id,
        orderid: order.number,
        payamount: (order.total.to_d * 100).to_s
      )
    end

    it 'completes payment and renders success' do
      expect { subject }.to change(order.payments, :count).by 1
      expect(subject.body).to eq 'OK'
      expect(order.payments.last).to have_attributes(
        source_type: payment_method.type,
        amount: order.total
      )
    end
  end

  describe '#confirm' do
    subject { get :confirm, params: params }
    let(:params) do
      {
        payment_method_id: payment_method.id,
        data: 'data'
      }
    end

    before do
      allow(controller).to receive(:parse).and_return(
        projectid: payment_method.preferred_project_id,
        orderid: order.number,
        payamount: (order.total.to_d * 100).to_s
      )
    end

    context 'when order is not completed' do
      it 'redirects to cart path' do
        expect(subject).to redirect_to cart_path
        expect(flash[:alert]).to be_present
      end
    end

    context 'when order already completed' do
      let(:order) do
        order = OrderWalkthrough.up_to(:complete)
        order.update payment_state: 'paid'
        order
      end

      it 'redirects to account path' do
        expect(subject).to redirect_to account_path
        expect(flash[:notice]).to be_present
      end
    end
  end

  describe '#cancel' do
    subject { get :cancel, params: params }
    let(:params) do
      { payment_method_id: payment_method.id }
    end

    it 'redirects to products path' do
      expect(subject).to redirect_to products_path
    end
  end
end
