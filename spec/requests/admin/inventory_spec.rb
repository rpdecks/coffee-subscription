require 'rails_helper'

RSpec.describe "Admin Inventory Management", type: :request do
  let(:admin_user) { create(:user, :admin) }
  let(:product) { create(:product, product_type: :coffee) }

  before { sign_in admin_user, scope: :user }

  describe "GET /admin/inventory" do
    let!(:inventory_item) { create(:inventory_item, product: product) }

    it "returns a successful response" do
      get admin_inventory_index_path
      expect(response).to have_http_status(:success)
    end

    it "displays inventory items" do
      get admin_inventory_index_path
      expect(response.body).to include(product.name)
    end

    it "displays summary statistics" do
      get admin_inventory_index_path
      expect(response.body).to include("Total Items")
      expect(response.body).to include("Low Stock")
      expect(response.body).to include("Expiring Soon")
    end

    context "with filters applied" do
      let(:merch_product) { create(:product, product_type: :merch) }
      let!(:merch_item) { create(:inventory_item, product: merch_product) }

      it "filters by product type" do
        get admin_inventory_index_path, params: { product_type: "coffee" }
        expect(response.body).to include(product.name)
        expect(response.body).not_to include(merch_product.name)
      end

      it "filters by state" do
        roasted_item = create(:inventory_item, :roasted, product: product)
        get admin_inventory_index_path, params: { state: "roasted" }
        expect(response.body).to include("Roasted")
      end

      it "searches by product name" do
        get admin_inventory_index_path, params: { search: product.name }
        expect(response.body).to include(product.name)
      end
    end
  end

  describe "GET /admin/inventory/new" do
    it "returns a successful response" do
      get new_admin_inventory_path
      expect(response).to have_http_status(:success)
    end

    it "displays the form" do
      get new_admin_inventory_path
      expect(response.body).to include("Add Inventory")
      expect(response.body).to include("State")
      expect(response.body).to include("Quantity")
    end
  end

  describe "POST /admin/inventory" do
    let(:valid_params) do
      {
        inventory_item: {
          product_id: product.id,
          state: "green",
          quantity: 25.0,
          lot_number: "LOT123",
          received_on: Date.today
        }
      }
    end

    it "creates a new inventory item" do
      expect {
        post admin_inventory_index_path, params: valid_params
      }.to change(InventoryItem, :count).by(1)
    end

    it "redirects to index with success message" do
      post admin_inventory_index_path, params: valid_params
      expect(response).to redirect_to(admin_inventory_index_path)
      follow_redirect!
      expect(response.body).to include("Inventory item created successfully")
    end

    context "with invalid params" do
      let(:invalid_params) do
        {
          inventory_item: {
            product_id: product.id,
            state: "green",
            quantity: nil
          }
        }
      end

      it "does not create an inventory item" do
        expect {
          post admin_inventory_index_path, params: invalid_params
        }.not_to change(InventoryItem, :count)
      end

      it "renders the new template with errors" do
        post admin_inventory_index_path, params: invalid_params
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("error")
      end
    end
  end

  describe "GET /admin/inventory/:id/edit" do
    let(:inventory_item) { create(:inventory_item, product: product) }

    it "returns a successful response" do
      get edit_admin_inventory_path(inventory_item)
      expect(response).to have_http_status(:success)
    end

    it "displays the edit form" do
      get edit_admin_inventory_path(inventory_item)
      expect(response.body).to include("Edit Inventory")
      expect(response.body).to include(inventory_item.quantity.to_s)
    end
  end

  describe "PATCH /admin/inventory/:id" do
    let(:inventory_item) { create(:inventory_item, product: product, quantity: 10) }
    let(:update_params) do
      {
        inventory_item: {
          quantity: 50.0,
          notes: "Updated quantity"
        }
      }
    end

    it "updates the inventory item" do
      patch admin_inventory_path(inventory_item), params: update_params
      inventory_item.reload
      expect(inventory_item.quantity).to eq(50.0)
      expect(inventory_item.notes).to eq("Updated quantity")
    end

    it "redirects to index with success message" do
      patch admin_inventory_path(inventory_item), params: update_params
      expect(response).to redirect_to(admin_inventory_index_path)
      follow_redirect!
      expect(response.body).to include("Inventory item updated successfully")
    end
  end

  describe "DELETE /admin/inventory/:id" do
    let!(:inventory_item) { create(:inventory_item, product: product) }

    it "deletes the inventory item" do
      expect {
        delete admin_inventory_path(inventory_item)
      }.to change(InventoryItem, :count).by(-1)
    end

    it "redirects to index with success message" do
      delete admin_inventory_path(inventory_item)
      expect(response).to redirect_to(admin_inventory_index_path)
      follow_redirect!
      expect(response.body).to include("Inventory item deleted successfully")
    end
  end

  describe "authorization" do
    context "when not signed in" do
      before { sign_out :user }

      it "redirects to sign in" do
        get admin_inventory_index_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when signed in as regular user" do
      let(:regular_user) { create(:user) }

      before do
        sign_out :user
        sign_in regular_user, scope: :user
      end

      it "redirects with authorization alert" do
        get admin_inventory_index_path
        expect(response).to redirect_to(root_path)
        follow_redirect!
        expect(flash[:alert]).to include("You are not authorized to perform this action.")
      end
    end
  end
end
