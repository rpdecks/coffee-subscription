require "rails_helper"

RSpec.describe Admin::RoastedInventoriesController, type: :controller do
  render_views
  let(:admin_user) { create(:admin_user) }
  let!(:product) { create(:product, product_type: :coffee) }
  let!(:green_item) { create(:inventory_item, :green, product: product, quantity: 15.0) }

  before do
    allow(controller).to receive(:authenticate_user!).and_return(true)
    allow(controller).to receive(:current_user).and_return(admin_user)
  end

  describe "GET #new" do
    it "renders the form" do
      get :new
      expect(response).to be_successful
      expect(assigns(:products)).to include(product)
    end
  end

  describe "POST #create" do
    it "creates a roasted inventory entry and debits green" do
      expect do
        post :create, params: {
          record_roast: {
            product_id: product.id,
            green_weight_used: 1.10,
            roasted_weight: 0.94,
            roasted_on: Date.today,
            batch_id: "CS-123",
            notes: "Fresh roast"
          }
        }
      end.to change { InventoryItem.roasted.count }.by(1)

      expect(response).to redirect_to(admin_inventory_index_path)
      expect(flash[:notice]).to include("Roasted inventory recorded")
      expect(green_item.reload.quantity).to eq(13.9)
    end

    it "renders errors when validation fails" do
      post :create, params: {
        record_roast: {
          product_id: "",
          green_weight_used: 0,
          roasted_weight: 0
        }
      }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
