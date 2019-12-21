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
        data: data,
        ss1: Digest::MD5.hexdigest(data + payment_method.preferred_sign_key),
        ss2: 'ss2'
      }
    end
    let(:data) do
      Base64.encode64("orderid=#{order.number}&payamount=#{order.total * 100}&projectid=#{payment_method.preferred_project_id}")
    end

    before do
      allow(controller).to receive_messages valid_ss2?: true
    end

    it 'completes payment and renders success' do
      expect { subject }.to change(order.payments, :count).by 1
      expect(subject.body).to eq 'OK'
      expect(order.payments.last).to have_attributes(
        source_type: payment_method.type,
        amount: order.total
      )
    end

    context 'when data is nil' do
      let(:params) do
        {
          payment_method_id: payment_method.id
        }
      end

      it_behaves_like 'error raiser'
    end

    context 'when projectid does not match' do
      let(:data) do
        Base64.encode64("orderid=#{order.number}&payamount=#{order.total * 100}")
      end

      it_behaves_like 'error raiser'
    end

    context 'when orderid is invalid' do
      let(:data) do
        Base64.encode64("orderid=1&payamount=#{order.total * 100}&projectid=#{payment_method.preferred_project_id}")
      end

      it_behaves_like 'error raiser'
    end

    context 'when payamount is less than order total' do
      let(:data) do
        Base64.encode64("orderid=#{order.number}&payamount=#{order.total * 100 - 1}&projectid=#{payment_method.preferred_project_id}")
      end

      it_behaves_like 'error raiser'
    end

    context 'when payamount is greater than order total' do
      let(:data) do
        Base64.encode64("orderid=#{order.number}&payamount=#{order.total * 100 + 1}&projectid=#{payment_method.preferred_project_id}")
      end

      it 'owes a credit' do
        expect { subject }.to change(order.payments, :count).by 1
        expect(subject.body).to start_with 'OK'
        expect(order.reload).to have_attributes(
          payment_state: 'credit_owed'
        )
      end
    end
  end

  describe '#confirm' do
    subject { get :confirm, params: params }
    let(:params) do
      {
        payment_method_id: payment_method.id,
        data: data,
        ss1: Digest::MD5.hexdigest(data + payment_method.preferred_sign_key),
        ss2: 'ss2'
      }
    end

    let(:data) do
      Base64.encode64("orderid=#{order.number}&payamount=#{order.total * 100}&projectid=#{payment_method.preferred_project_id}")
    end

    before do
      allow(controller).to receive_messages valid_ss2?: true
    end

    context 'when data is not present' do
      let(:params) do
        {
          payment_method_id: payment_method.id
        }
      end

      it_behaves_like 'account redirector'

      it 'sets alert flash' do
        subject
        expect(flash[:alert]).to be_present
      end
    end

    context 'when ss1 is not present' do
      let(:params) do
        {
          payment_method_id: payment_method.id,
          data: data
        }
      end

      it_behaves_like 'account redirector'

      it 'sets alert flash' do
        subject
        expect(flash[:alert]).to be_present
      end
    end

    context 'when ss2 is not present' do
      let(:params) do
        {
          payment_method_id: payment_method.id,
          data: data,
          ss1: 'adad'
        }
      end

      it_behaves_like 'account redirector'

      it 'sets alert flash' do
        subject
        expect(flash[:alert]).to be_present
      end
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
