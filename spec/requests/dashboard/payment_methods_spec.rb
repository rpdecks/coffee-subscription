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
        expect(response.body).to include(pm.display_name)
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
      it "creates a new payment method" do
        allow(StripeService).to receive(:attach_payment_method).and_return(
          user.payment_methods.create!(
            stripe_payment_method_id: 'pm_test123',
            card_brand: 'Visa',
            last_four: '4242',
            exp_month: 12,
            exp_year: 2025
          )
        )

        expect {
          post dashboard_payment_methods_path, params: { stripe_payment_method_id: 'pm_test123' }
        }.to change(user.payment_methods, :count).by(1)

        expect(response).to redirect_to(dashboard_payment_methods_path)
        expect(flash[:notice]).to include('successfully')
      end

      it "sets as default for first payment method" do
        allow(StripeService).to receive(:attach_payment_method).with(
          user: user,
          payment_method_id: 'pm_test123',
          set_as_default: true
        ).and_return(
          user.payment_methods.create!(
            stripe_payment_method_id: 'pm_test123',
            card_brand: 'Visa',
            last_four: '4242',
            exp_month: 12,
            exp_year: 2025,
            is_default: true
          )
        )

        post dashboard_payment_methods_path, params: { stripe_payment_method_id: 'pm_test123' }

        expect(user.payment_methods.last.is_default).to be true
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
      it "redirects with error message" do
        allow(StripeService).to receive(:attach_payment_method).and_raise(
          StripeService::StripeError.new('Card declined')
        )

        post dashboard_payment_methods_path, params: { stripe_payment_method_id: 'pm_test123' }
        
        expect(response).to redirect_to(new_dashboard_payment_method_path)
        expect(flash[:alert]).to include('Card declined')
      end
    end
  end

  describe "POST /dashboard/payment_methods/:id/set_default" do
    let!(:payment_method) { create(:payment_method, user: user, is_default: false) }
    let!(:default_pm) { create(:payment_method, user: user, is_default: true) }

    it "sets payment method as default" do
      allow(StripeService).to receive(:attach_payment_method)

      post set_default_dashboard_payment_method_path(payment_method)

      expect(payment_method.reload.is_default).to be true
      expect(default_pm.reload.is_default).to be false
    end

    it "updates Stripe customer default" do
      expect(StripeService).to receive(:attach_payment_method).with(
        user: user,
        payment_method_id: payment_method.stripe_payment_method_id,
        set_as_default: true
      )

      post set_default_dashboard_payment_method_path(payment_method)
    end
  end

  describe "DELETE /dashboard/payment_methods/:id" do
    let!(:payment_method) { create(:payment_method, user: user, is_default: false) }

    context "when not default and no active subscription" do
      it "deletes the payment method" do
        allow(StripeService).to receive(:detach_payment_method)

        expect {
          delete dashboard_payment_method_path(payment_method)
        }.to change(user.payment_methods, :count).by(-1)

        expect(response).to redirect_to(dashboard_payment_methods_path)
        expect(flash[:notice]).to include('removed')
      end

      it "detaches from Stripe" do
        expect(StripeService).to receive(:detach_payment_method).with(
          payment_method.stripe_payment_method_id
        )

        delete dashboard_payment_method_path(payment_method)
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
      it "redirects with error message" do
        allow(StripeService).to receive(:detach_payment_method).and_raise(
          StripeService::StripeError.new('Payment method not found')
        )

        delete dashboard_payment_method_path(payment_method)
        
        expect(flash[:alert]).to include('Payment method not found')
      end
    end
  end
end
