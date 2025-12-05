require 'rails_helper'

RSpec.describe "Dashboard::Subscription Address Management", type: :request do
  let(:user) { create(:customer_user) }
  let(:plan) { create(:subscription_plan) }
  let(:address1) { create(:address, user: user, address_type: :shipping, street_address: "123 Main St") }
  let(:address2) { create(:address, user: user, address_type: :shipping, street_address: "456 Coffee Lane", is_default: false) }
  let!(:subscription) do
    create(:subscription,
      user: user,
      subscription_plan: plan,
      shipping_address: address1,
      status: :active
    )
  end

  before do
    sign_in user, scope: :user
  end

  describe "GET /dashboard/subscriptions/:id" do
    context "with shipping address" do
      it "displays the shipping address" do
        get dashboard_subscription_path(subscription)

        expect(response).to have_http_status(:success)
        expect(response.body).to include(address1.street_address)
        expect(response.body).to include(address1.city)
      end

      it "shows change button when multiple addresses exist" do
        address2 # Create second address

        get dashboard_subscription_path(subscription)

        expect(response.body).to include("Change")
      end

      it "does not show change button with only one address" do
        get dashboard_subscription_path(subscription)

        expect(response.body).not_to include("Change")
      end
    end

    context "without shipping address" do
      before do
        subscription.update(shipping_address: nil)
      end

      it "displays warning message" do
        get dashboard_subscription_path(subscription)

        expect(response).to have_http_status(:success)
        expect(response.body).to include("No shipping address set")
      end

      it "shows link to add address" do
        get dashboard_subscription_path(subscription)

        expect(response.body).to include("Add Address")
      end
    end
  end

  describe "PATCH /dashboard/subscriptions/:id/update_address" do
    before do
      address2 # Ensure second address exists
    end

    context "with valid address" do
      it "updates the subscription shipping address" do
        patch update_address_dashboard_subscription_path(subscription), params: { address_id: address2.id }

        expect(response).to redirect_to(dashboard_subscription_path(subscription))
        expect(flash[:notice]).to eq("Shipping address updated successfully.")

        subscription.reload
        expect(subscription.shipping_address_id).to eq(address2.id)
      end

      it "changes from one address to another" do
        expect(subscription.shipping_address_id).to eq(address1.id)

        patch update_address_dashboard_subscription_path(subscription), params: { address_id: address2.id }

        subscription.reload
        expect(subscription.shipping_address_id).to eq(address2.id)
        expect(subscription.shipping_address.street_address).to eq("456 Coffee Lane")
      end
    end

    context "with invalid address" do
      it "redirects with error for non-existent address" do
        patch update_address_dashboard_subscription_path(subscription), params: { address_id: 99999 }

        expect(response).to redirect_to(dashboard_subscription_path(subscription))
        expect(flash[:alert]).to eq("Address not found.")

        subscription.reload
        expect(subscription.shipping_address_id).to eq(address1.id) # Unchanged
      end

      it "prevents using another user's address" do
        other_user = create(:user)
        other_address = create(:address, user: other_user, address_type: :shipping)

        patch update_address_dashboard_subscription_path(subscription), params: { address_id: other_address.id }

        expect(response).to redirect_to(dashboard_subscription_path(subscription))
        expect(flash[:alert]).to eq("Address not found.")

        subscription.reload
        expect(subscription.shipping_address_id).to eq(address1.id) # Unchanged
      end
    end

    context "for inactive subscription" do
      before do
        subscription.update(status: :cancelled)
        address2
      end

      it "still allows address updates" do
        patch update_address_dashboard_subscription_path(subscription), params: { address_id: address2.id }

        expect(response).to redirect_to(dashboard_subscription_path(subscription))
        subscription.reload
        expect(subscription.shipping_address_id).to eq(address2.id)
      end
    end
  end

  describe "Address deletion prevention" do
    context "when address is used by active subscription" do
      it "should handle address deletion gracefully" do
        # This is more of a model test but relevant to the feature
        expect {
          address1.destroy
        }.not_to raise_error

        subscription.reload
        expect(subscription.shipping_address).to be_nil
      end
    end
  end
end
