require 'rails_helper'

RSpec.describe "Dashboard::PaymentMethods", type: :request do
  let(:user) { create(:customer_user, stripe_customer_id: 'cus_test123') }

  before do
    sign_in user, scope: :user
  end

  describe "GET /dashboard/payment_methods" do
    let!(:payment_methods) { create_list(:payment_method, 3, user: user) }

    it "returns http success" do
      get dashboard_payment_methods_path
      expect(response).to have_http_status(:success)
    end

    it "displays all payment methods" do
      get dashboard_payment_methods_path
      payment_methods.each do |pm|
        # View shows "Visa •••• 4242" format, not display_name
        expect(response.body).to include(pm.card_brand.capitalize)
        expect(response.body).to include(pm.last_four)
      end
    end

    it "includes Stripe publishable key" do
      get dashboard_payment_methods_path
      expect(assigns(:stripe_publishable_key)).to be_present
    end
  end

  describe "GET /dashboard/payment_methods/new" do
    it "returns http success" do
      get new_dashboard_payment_method_path
      expect(response).to have_http_status(:success)
    end

    it "includes Stripe publishable key" do
      get new_dashboard_payment_method_path
      expect(assigns(:stripe_publishable_key)).to be_present
    end
  end

  describe "POST /dashboard/payment_methods" do
    context "with valid payment method ID" do
      let(:stripe_pm) do
        double('Stripe::PaymentMethod',
          id: 'pm_test123',
          card: double('card',
            brand: 'visa',
            last4: '4242',
            exp_month: 12,
            exp_year: 2025
          )
        )
      end

      before do
        allow(Stripe::PaymentMethod).to receive(:attach).and_return(stripe_pm)
        allow(Stripe::Customer).to receive(:update)
      end

      it "creates a new payment method" do
        expect {
          post dashboard_payment_methods_path, params: { stripe_payment_method_id: 'pm_test123' }
        }.to change(user.payment_methods, :count).by(1)

        expect(response).to redirect_to(dashboard_payment_methods_path)
        expect(flash[:notice]).to include('successfully')
      end

      it "sets as default for first payment method" do
        post dashboard_payment_methods_path, params: { stripe_payment_method_id: 'pm_test123' }

        expect(user.payment_methods.last.is_default).to be true
        expect(Stripe::Customer).to have_received(:update).with(
          user.stripe_customer_id,
          invoice_settings: { default_payment_method: 'pm_test123' }
        )
      end
    end

    context "without payment method ID" do
      it "redirects with error" do
        post dashboard_payment_methods_path, params: {}

        expect(response).to redirect_to(new_dashboard_payment_method_path)
        expect(flash[:alert]).to be_present
      end
    end

    context "when Stripe service fails" do
      before do
        allow(Stripe::PaymentMethod).to receive(:attach).and_raise(
          Stripe::CardError.new('Card declined', nil, code: 'card_declined')
        )
      end

      it "redirects with error message" do
        post dashboard_payment_methods_path, params: { stripe_payment_method_id: 'pm_test123' }

        expect(response).to redirect_to(new_dashboard_payment_method_path)
        expect(flash[:alert]).to include('Card declined')
      end
    end
  end

  describe "POST /dashboard/payment_methods/:id/set_default" do
    let!(:payment_method) { create(:payment_method, user: user, is_default: false) }
    let!(:default_pm) { create(:payment_method, user: user, is_default: true) }
    let(:stripe_pm) do
      double('Stripe::PaymentMethod',
        id: payment_method.stripe_payment_method_id,
        card: double('card',
          brand: payment_method.card_brand,
          last4: payment_method.last_four,
          exp_month: payment_method.exp_month,
          exp_year: payment_method.exp_year
        )
      )
    end

    before do
      allow(Stripe::PaymentMethod).to receive(:attach).and_return(stripe_pm)
      allow(Stripe::Customer).to receive(:update)
    end

    it "sets payment method as default" do
      post set_default_dashboard_payment_method_path(payment_method)

      expect(payment_method.reload.is_default).to be true
      expect(default_pm.reload.is_default).to be false
    end

    it "updates Stripe customer default" do
      post set_default_dashboard_payment_method_path(payment_method)

      expect(Stripe::Customer).to have_received(:update).with(
        user.stripe_customer_id,
        invoice_settings: { default_payment_method: payment_method.stripe_payment_method_id }
      )
    end
  end

  describe "DELETE /dashboard/payment_methods/:id" do
    let!(:payment_method) { create(:payment_method, user: user, is_default: false) }

    context "when not default and no active subscription" do
      before do
        allow(Stripe::PaymentMethod).to receive(:detach)
      end

      it "deletes the payment method" do
        expect {
          delete dashboard_payment_method_path(payment_method)
        }.to change(user.payment_methods, :count).by(-1)

        expect(response).to redirect_to(dashboard_payment_methods_path)
        expect(flash[:notice]).to include('removed')
      end

      it "detaches from Stripe" do
        delete dashboard_payment_method_path(payment_method)

        expect(Stripe::PaymentMethod).to have_received(:detach).with(
          payment_method.stripe_payment_method_id
        )
      end
    end

    context "when default with active subscription" do
      let!(:payment_method) { create(:payment_method, user: user, is_default: true) }
      let!(:subscription) { create(:subscription, :active, user: user) }

      it "prevents deletion" do
        expect {
          delete dashboard_payment_method_path(payment_method)
        }.not_to change(user.payment_methods, :count)

        expect(response).to redirect_to(dashboard_payment_methods_path)
        expect(flash[:alert]).to include('Cannot remove')
      end
    end

    context "when Stripe service fails" do
      before do
        allow(Stripe::PaymentMethod).to receive(:detach).and_raise(
          Stripe::InvalidRequestError.new('Payment method not found', nil)
        )
      end

      it "redirects with error message" do
        delete dashboard_payment_method_path(payment_method)

        expect(flash[:alert]).to include('Payment method not found')
      end
    end
  end
end
