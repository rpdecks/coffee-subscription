# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::RoastedInventories", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:product) { create(:product, name: "Palmatum Blend", product_type: :coffee) }
  let!(:green_item) { create(:inventory_item, :green, product: product, quantity: 15.0) }

  before { sign_in admin, scope: :user }

  describe "GET /admin/roasted_inventories/new" do
    it "renders the form" do
      get new_admin_roasted_inventory_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Record Roasted Inventory")
      expect(response.body).to include("Green weight used")
      expect(response.body).to include("Roasted weight")
    end

    it "shows green inventory for each product" do
      get new_admin_roasted_inventory_path
      expect(response.body).to include("15.00 lbs green available")
    end

    context "with prefill params (duplicate)" do
      it "pre-fills the form with values from another roast" do
        get new_admin_roasted_inventory_path, params: {
          prefill: {
            product_id: product.id,
            green_weight_used: "1.10",
            roasted_weight: "0.94",
            lot_number: "PAL-2026-02-16-A",
            batch_id: "B001"
          }
        }
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Palmatum Blend")
        expect(response.body).to include("1.10")
        expect(response.body).to include("0.94")
        expect(response.body).to include("PAL-2026-02-16-A")
        expect(response.body).to include("B001")
      end
    end
  end

  describe "POST /admin/roasted_inventories" do
    let(:valid_params) do
      {
        record_roast: {
          product_id: product.id,
          green_weight_used: "1.10",
          roasted_weight: "0.94",
          roasted_on: Date.today.to_s,
          lot_number: "PAL-2026-02-16",
          notes: "Test batch"
        }
      }
    end

    context "with valid params" do
      it "creates roasted inventory and debits green" do
        expect {
          post admin_roasted_inventories_path, params: valid_params
        }.to change { InventoryItem.roasted.count }.by(1)

        expect(green_item.reload.quantity).to eq(13.9)
        expect(response).to redirect_to(admin_inventory_index_path)
        follow_redirect!
        expect(response.body).to include("Roasted inventory recorded")
        expect(response.body).to include("Green debited")
        expect(response.body).to include("Weight loss")
      end
    end

    context "with invalid params (green <= roasted)" do
      let(:invalid_params) do
        {
          record_roast: {
            product_id: product.id,
            green_weight_used: "0.90",
            roasted_weight: "0.94",
            roasted_on: Date.today.to_s
          }
        }
      end

      it "re-renders the form with errors" do
        expect {
          post admin_roasted_inventories_path, params: invalid_params
        }.not_to change { InventoryItem.count }

        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "with missing product" do
      it "re-renders the form with errors" do
        post admin_roasted_inventories_path, params: {
          record_roast: {
            product_id: "",
            green_weight_used: "1.10",
            roasted_weight: "0.94",
            roasted_on: Date.today.to_s
          }
        }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "when green inventory is insufficient" do
      let!(:green_item) { create(:inventory_item, :green, product: product, quantity: 0.5) }

      it "still records roast with warning" do
        post admin_roasted_inventories_path, params: valid_params
        expect(response).to redirect_to(admin_inventory_index_path)
        follow_redirect!
        expect(response.body).to include("could not be debited")
      end
    end

    it "requires admin authentication" do
      sign_out admin
      post admin_roasted_inventories_path, params: valid_params
      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
