# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::BlendComponents", type: :request do
  let(:admin) { create(:admin_user) }
  let(:product) { create(:product) }
  let(:supplier) { create(:supplier) }
  let(:green_coffee) { create(:green_coffee, supplier: supplier) }

  before { sign_in admin, scope: :user }

  describe "GET /admin/products/:product_id/blend_components/new" do
    it "returns http success" do
      get new_admin_product_blend_component_path(product)
      expect(response).to have_http_status(:success)
    end

    it "excludes already-used green coffees" do
      used_gc = create(:green_coffee, supplier: supplier, name: "Already Used")
      create(:blend_component, product: product, green_coffee: used_gc, percentage: 50)
      available_gc = create(:green_coffee, supplier: supplier, name: "Available GC")

      get new_admin_product_blend_component_path(product)
      expect(response.body).not_to include("Already Used")
      expect(response.body).to include("Available GC")
    end
  end

  describe "POST /admin/products/:product_id/blend_components" do
    let(:valid_attributes) do
      { green_coffee_id: green_coffee.id, percentage: 100 }
    end

    it "creates a new blend component" do
      expect {
        post admin_product_blend_components_path(product), params: { blend_component: valid_attributes }
      }.to change(BlendComponent, :count).by(1)
    end

    it "redirects to product show page" do
      post admin_product_blend_components_path(product), params: { blend_component: valid_attributes }
      expect(response).to redirect_to(admin_product_path(product))
    end

    it "associates the component with the correct product" do
      post admin_product_blend_components_path(product), params: { blend_component: valid_attributes }
      expect(BlendComponent.last.product).to eq(product)
    end

    context "with invalid attributes" do
      it "does not create without percentage" do
        expect {
          post admin_product_blend_components_path(product),
            params: { blend_component: { green_coffee_id: green_coffee.id, percentage: nil } }
        }.not_to change(BlendComponent, :count)
      end

      it "renders new with unprocessable status" do
        post admin_product_blend_components_path(product),
          params: { blend_component: { green_coffee_id: green_coffee.id, percentage: nil } }
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "rejects percentage over 100" do
        expect {
          post admin_product_blend_components_path(product),
            params: { blend_component: { green_coffee_id: green_coffee.id, percentage: 150 } }
        }.not_to change(BlendComponent, :count)
      end
    end

    context "when total would exceed 100%" do
      before do
        other_gc = create(:green_coffee, supplier: supplier)
        create(:blend_component, product: product, green_coffee: other_gc, percentage: 80)
      end

      it "rejects the component" do
        expect {
          post admin_product_blend_components_path(product),
            params: { blend_component: { green_coffee_id: green_coffee.id, percentage: 30 } }
        }.not_to change(BlendComponent, :count)
      end
    end
  end

  describe "GET /admin/products/:product_id/blend_components/:id/edit" do
    let!(:component) { create(:blend_component, product: product, green_coffee: green_coffee, percentage: 60) }

    it "returns http success" do
      get edit_admin_product_blend_component_path(product, component)
      expect(response).to have_http_status(:success)
    end
  end

  describe "PATCH /admin/products/:product_id/blend_components/:id" do
    let!(:component) { create(:blend_component, product: product, green_coffee: green_coffee, percentage: 60) }

    it "updates the blend component" do
      patch admin_product_blend_component_path(product, component),
        params: { blend_component: { percentage: 80 } }
      expect(component.reload.percentage).to eq(80)
    end

    it "redirects to product show page" do
      patch admin_product_blend_component_path(product, component),
        params: { blend_component: { percentage: 80 } }
      expect(response).to redirect_to(admin_product_path(product))
    end

    context "with invalid attributes" do
      it "renders edit with unprocessable status" do
        patch admin_product_blend_component_path(product, component),
          params: { blend_component: { percentage: 0 } }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "DELETE /admin/products/:product_id/blend_components/:id" do
    let!(:component) { create(:blend_component, product: product, green_coffee: green_coffee, percentage: 60) }

    it "destroys the blend component" do
      expect {
        delete admin_product_blend_component_path(product, component)
      }.to change(BlendComponent, :count).by(-1)
    end

    it "redirects to product show page" do
      delete admin_product_blend_component_path(product, component)
      expect(response).to redirect_to(admin_product_path(product))
    end
  end
end
