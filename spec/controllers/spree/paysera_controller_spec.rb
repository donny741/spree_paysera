# frozen_string_literal: true

RSpec.describe Spree::PayseraController, type: :controller do
  let(:user) { create(:user) }
  let(:order) { OrderWalkthrough.up_to(:payment) }
  let(:payment_method) { create(:paysera_gateway) }

  shared_examples 'error raiser' do
    it 'raises an error' do
      expect(subject.body).to start_with 'Error'
    end
  end

  shared_examples 'account redirector' do
    it 'redirects to product path' do
      expect(subject).to redirect_to account_path
    end
  end

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

    context 'when payment_method_id is invalid' do
      let(:params) do
        { payment_method_id: payment_method.id + 1 }
      end

      it_behaves_like 'error raiser'
    end
  end

  describe '#callback' do
    subject { get :callback, params: params }

    let(:params) do
      {
        payment_method_id: payment_method.id,
      }
    end
    let(:orderid) { order.number }
    let(:payamount) { (order.total * 100).to_s }
    let(:projectid) { payment_method.preferred_project_id.to_s }

    before do
      expect(Spree::Paysera::ParseResponse).to receive(:for).and_return(
        orderid: orderid,
        payamount: payamount,
        projectid: projectid
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

    context 'when projectid does not match' do
      let(:projectid) { payment_method.preferred_project_id + 1 }

      it_behaves_like 'error raiser'
    end

    context 'when orderid is invalid' do
      let(:orderid) { 'invalid order number '}

      it_behaves_like 'error raiser'
    end
  end

  if ENV['SIGN_PASSWORD']
    describe '#callback with real request data' do
      subject { get :callback, params: params }
      let(:order) do
        order = OrderWalkthrough.up_to(:payment)
        order.update(number: ENV.fetch('ORDER_NUMBER'), total: order_total)
        order
      end

      let(:params) do
        {
          payment_method_id: payment_method.id,
          data: data,
          ss1: ss1,
          ss2: ss2
        }
      end
      let(:data) { ENV['DATA'] }
      let(:ss1) { ENV['SS1'] }
      let(:ss2) { ENV['SS2'] }
      let(:order_total) { ENV.fetch('ORDER_TOTAL').to_d }

      it 'completes the order' do
        expect(subject.body).to start_with('OK')
      end

      context 'when data is invalid' do
        let(:data) { ENV['DATA'] + 'a' }

        it 'responds with error' do
          expect(subject.body).to start_with('Error')
        end
      end

      context 'when ss1 is invalid' do
        let(:ss1) { ENV['SS1'] + 'a' }

        it 'responds with error' do
          expect(subject.body).to start_with('Error')
        end
      end

      context 'when ss2 is invalid' do
        let(:ss2) { 'a' + ENV['SS2']}

        it 'responds with error' do
          expect(subject.body).to start_with('Error')
        end
      end

      context 'when payamount is greater than order total' do
        let(:order_total) { ENV.fetch('ORDER_TOTAL').to_d - 1.to_d }

        it 'completes the order' do
          expect(subject.body).to start_with('OK')
        end
      end

      context 'when payamount is less than order total' do
        let(:order_total) { ENV.fetch('ORDER_TOTAL').to_d + 1.to_d }

        it 'responds with error' do
          expect(subject.body).to start_with('Error')
        end
      end
    end
  end

  describe '#confirm' do
    subject { get :confirm, params: params }

    let(:params) do
      {
        payment_method_id: payment_method.id,
      }
    end
    let(:orderid) { order.number }

    before do
      expect(Spree::Paysera::ParseResponse).to receive(:for).and_return(
        orderid: orderid
      )
    end

    context 'when order is not completed' do
      it_behaves_like 'account redirector'

      it 'sets alert flash' do
        subject
        expect(flash[:alert]).to be_present
      end
    end

    context 'when order already completed' do
      let(:order) do
        order = OrderWalkthrough.up_to(:complete)
        order.update payment_state: 'paid'
        order
      end

      it_behaves_like 'account redirector'

      it 'sets notice flash' do
        subject
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
