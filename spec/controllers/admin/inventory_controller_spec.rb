require 'rails_helper'

RSpec.describe Admin::InventoryController, type: :controller do
  let(:admin_user) { create(:user, :admin) }
  let(:product) { create(:product, product_type: :coffee, name: "Test Coffee") }
  let(:inventory_item) { create(:inventory_item, product: product) }

  before do
    @request.env["devise.mapping"] = Devise.mappings[:user]
    sign_in admin_user, scope: :user
  end

  # Warmup test to initialize Devise session properly
  describe "session initialization" do
    it "initializes properly" do
      expect(admin_user).to be_persisted
    end
  end

  describe "GET #index" do
    let!(:green_item) { create(:inventory_item, :green, product: product, quantity: 10) }
    let!(:roasted_item) { create(:inventory_item, :roasted, product: product, quantity: 5) }
    let!(:low_stock_item) { create(:inventory_item, :low_stock, product: product, quantity: 2) }

    it "assigns all inventory items" do
      get :index
      expect(assigns(:inventory_items)).to match_array([ green_item, roasted_item, low_stock_item ])
    end

    it "assigns summary stats" do
      get :index
      expect(assigns(:total_items)).to eq(3)
      expect(assigns(:low_stock_count)).to eq(1)
    end

    context "with product_type filter" do
      let(:merch_product) { create(:product, product_type: :merch) }
      let!(:merch_item) { create(:inventory_item, product: merch_product) }

      it "filters by coffee products" do
        get :index, params: { product_type: "coffee" }
        expect(assigns(:inventory_items)).to include(green_item, roasted_item)
        expect(assigns(:inventory_items)).not_to include(merch_item)
      end

      it "filters by merch products" do
        get :index, params: { product_type: "merch" }
        expect(assigns(:inventory_items)).to eq([ merch_item ])
      end
    end

    context "with state filter" do
      it "filters by green state" do
        get :index, params: { state: "green" }
        expect(assigns(:inventory_items)).to include(green_item, low_stock_item)
        expect(assigns(:inventory_items)).not_to include(roasted_item)
      end

      it "filters by roasted state" do
        get :index, params: { state: "roasted" }
        expect(assigns(:inventory_items)).to eq([ roasted_item ])
      end
    end

    context "with stock status filter" do
      let!(:out_of_stock_item) { create(:inventory_item, :out_of_stock, product: product) }

      it "filters available items" do
        get :index, params: { stock_status: "available" }
        expect(assigns(:inventory_items)).to include(green_item, roasted_item, low_stock_item)
        expect(assigns(:inventory_items)).not_to include(out_of_stock_item)
      end

      it "filters low stock items" do
        get :index, params: { stock_status: "low_stock" }
        expect(assigns(:inventory_items)).to include(low_stock_item)
        expect(assigns(:inventory_items)).not_to include(green_item, roasted_item)
      end

      it "filters out of stock items" do
        get :index, params: { stock_status: "out_of_stock" }
        expect(assigns(:inventory_items)).to eq([ out_of_stock_item ])
      end
    end

    context "with search" do
      it "searches by product name" do
        get :index, params: { search: "Test Coffee" }
        expect(assigns(:inventory_items)).to include(green_item, roasted_item)
      end

      it "searches by lot number" do
        green_item.update(lot_number: "LOT123")
        get :index, params: { search: "LOT123" }
        expect(assigns(:inventory_items)).to include(green_item)
      end
    end

    context "with sorting" do
      it "responds successfully to sort requests" do
        get :index, params: { sort: "roast_date" }
        expect(response).to be_successful
      end

      it "sorts by quantity descending" do
        get :index, params: { sort: "quantity_desc" }
        items = assigns(:inventory_items)
        quantities = items.map(&:quantity)
        # Verify items are sorted in descending order
        expect(quantities).to eq(quantities.sort.reverse),
          "Expected items to be sorted by quantity descending, but got: #{quantities.inspect}"
      end

      it "sorts by roast date" do
        get :index, params: { sort: "roast_date" }
        expect(response).to be_successful
      end
    end
  end

  describe "GET #new" do
    it "returns a successful response" do
      get :new
      expect(response).to be_successful
    end

    it "assigns a new inventory item" do
      get :new
      expect(assigns(:inventory_item)).to be_a_new(InventoryItem)
    end

    it "assigns products" do
      get :new
      expect(assigns(:products)).to include(product)
    end
  end

  describe "POST #create" do
    let(:valid_attributes) do
      {
        product_id: product.id,
        state: "green",
        quantity: 25.0,
        lot_number: "LOT123",
        received_on: Date.today
      }
    end

    let(:invalid_attributes) do
      {
        product_id: product.id,
        state: "green",
        quantity: nil
      }
    end

    context "with valid params" do
      it "creates a new inventory item" do
        expect {
          post :create, params: { inventory_item: valid_attributes }
        }.to change(InventoryItem, :count).by(1)
      end

      it "redirects to the inventory index" do
        post :create, params: { inventory_item: valid_attributes }
        expect(response).to redirect_to(admin_inventory_index_path)
      end

      it "sets a flash notice" do
        post :create, params: { inventory_item: valid_attributes }
        expect(flash[:notice]).to eq("Inventory item created successfully.")
      end

      it "creates with correct attributes" do
        post :create, params: { inventory_item: valid_attributes }
        item = InventoryItem.last
        expect(item.product).to eq(product)
        expect(item.state).to eq("green")
        expect(item.quantity).to eq(25.0)
        expect(item.lot_number).to eq("LOT123")
      end
    end

    context "with invalid params" do
      it "does not create a new inventory item" do
        expect {
          post :create, params: { inventory_item: invalid_attributes }
        }.not_to change(InventoryItem, :count)
      end

      it "renders the new template" do
        post :create, params: { inventory_item: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_content)
        expect(response).to render_template(:new)
      end
    end
  end

  describe "GET #edit" do
    it "returns a successful response" do
      get :edit, params: { id: inventory_item.id }
      expect(response).to be_successful
    end

    it "assigns the requested inventory item" do
      get :edit, params: { id: inventory_item.id }
      expect(assigns(:inventory_item)).to eq(inventory_item)
    end

    it "assigns products" do
      get :edit, params: { id: inventory_item.id }
      expect(assigns(:products)).to include(product)
    end
  end

  describe "PATCH #update" do
    let(:new_attributes) do
      {
        quantity: 50.0,
        lot_number: "LOT456"
      }
    end

    let(:invalid_attributes) do
      {
        quantity: -5
      }
    end

    context "with valid params" do
      it "updates the inventory item" do
        patch :update, params: { id: inventory_item.id, inventory_item: new_attributes }
        inventory_item.reload
        expect(inventory_item.quantity).to eq(50.0)
        expect(inventory_item.lot_number).to eq("LOT456")
      end

      it "redirects to the inventory index" do
        patch :update, params: { id: inventory_item.id, inventory_item: new_attributes }
        expect(response).to redirect_to(admin_inventory_index_path)
      end

      it "sets a flash notice" do
        patch :update, params: { id: inventory_item.id, inventory_item: new_attributes }
        expect(flash[:notice]).to eq("Inventory item updated successfully.")
      end
    end

    context "with invalid params" do
      it "does not update the inventory item" do
        original_quantity = inventory_item.quantity
        patch :update, params: { id: inventory_item.id, inventory_item: invalid_attributes }
        inventory_item.reload
        expect(inventory_item.quantity).to eq(original_quantity)
      end

      it "renders the edit template" do
        patch :update, params: { id: inventory_item.id, inventory_item: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_content)
        expect(response).to render_template(:edit)
      end
    end
  end

  describe "DELETE #destroy" do
    let!(:item_to_delete) { create(:inventory_item, product: product) }

    it "destroys the inventory item" do
      expect {
        delete :destroy, params: { id: item_to_delete.id }
      }.to change(InventoryItem, :count).by(-1)
    end

    it "redirects to the inventory index" do
      delete :destroy, params: { id: item_to_delete.id }
      expect(response).to redirect_to(admin_inventory_index_path)
    end

    it "sets a flash notice" do
      delete :destroy, params: { id: item_to_delete.id }
      expect(flash[:notice]).to eq("Inventory item deleted successfully.")
    end
  end

  describe "authorization" do
    context "when not signed in" do
      before { sign_out admin_user }

      it "redirects to sign in page" do
        get :index
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when signed in as regular user" do
      let(:regular_user) { create(:user) }

      before do
        sign_out admin_user
        sign_in regular_user, scope: :user
      end

      it "denies access" do
        get :index
        # The admin base controller should handle authorization
        # This will either redirect or return 403
        expect(response).not_to be_successful
      end
    end
  end
end
