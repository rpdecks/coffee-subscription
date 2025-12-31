# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Admin::Products", type: :request do
  let(:admin) { create(:admin_user) }
  let!(:products) { create_list(:product, 3) }

  before do
    sign_in admin, scope: :user
  end

  describe "GET /admin/products" do
    it "returns http success" do
      get admin_products_path
      expect(response).to have_http_status(:success)
    end

    it "displays all products" do
      get admin_products_path
      products.each do |product|
        expect(response.body).to include(product.name)
      end
    end

    context "with pagination" do
      before { create_list(:product, 30) }

      it "paginates results" do
        get admin_products_path
        expect(response.body).to match(/pagination/i)
      end
    end

    context "with type filter" do
      let!(:coffee_product) { create(:product, :coffee) }
      let!(:merch_product) { create(:product, :merch) }

      it "filters by coffee type" do
        get admin_products_path, params: { product_type: "coffee" }
        expect(response.body).to include(coffee_product.name)
      end

      it "filters by merch type" do
        get admin_products_path, params: { product_type: "merch" }
        expect(response.body).to include(merch_product.name)
      end
    end

    context "with active filter" do
      let!(:active_product) { create(:product, active: true) }
      let!(:inactive_product) { create(:product, :inactive) }

      it "filters by active products" do
        get admin_products_path, params: { active: "true" }
        expect(response.body).to include(active_product.name)
      end

      it "filters by inactive products" do
        get admin_products_path, params: { active: "false" }
        expect(response.body).to include(inactive_product.name)
      end
    end
  end

  describe "GET /admin/products/:id" do
    let(:product) { products.first }

    it "returns http success" do
      get admin_product_path(product)
      expect(response).to have_http_status(:success)
    end

    it "displays product details" do
      get admin_product_path(product)
      expect(response.body).to include(product.name)
      expect(response.body).to include(product.description)
    end
  end

  describe "GET /admin/products/new" do
    it "returns http success" do
      get new_admin_product_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /admin/products" do
    let(:valid_attributes) do
      {
        name: "New Coffee",
        description: "Delicious new coffee",
        product_type: "coffee",
        price: 20.00,
        weight_oz: 12,
        inventory_count: 50,
        active: true
      }
    end

    it "creates a new product" do
      expect {
        post admin_products_path, params: { product: valid_attributes }
      }.to change(Product, :count).by(1)
    end

    it "redirects to product show page" do
      post admin_products_path, params: { product: valid_attributes }
      expect(response).to redirect_to(admin_product_path(Product.last))
    end
  end

  describe "GET /admin/products/:id/edit" do
    let(:product) { products.first }

    it "returns http success" do
      get edit_admin_product_path(product)
      expect(response).to have_http_status(:success)
    end
  end

  describe "PATCH /admin/products/:id" do
    let(:product) { products.first }

    it "updates the product" do
      patch admin_product_path(product), params: { product: { name: "Updated Name" } }
      expect(product.reload.name).to eq("Updated Name")
    end

    it "redirects to product show page" do
      patch admin_product_path(product), params: { product: { name: "Updated Name" } }
      expect(response).to redirect_to(admin_product_path(product))
    end
  end

  describe "PATCH /admin/products/:product_id/images/:attachment_id/feature" do
    let(:product) { products.first }

    it "sets the featured image and moves it to the front of the order" do
      product.images.attach(io: StringIO.new("a"), filename: "a.png", content_type: "image/png")
      product.images.attach(io: StringIO.new("b"), filename: "b.png", content_type: "image/png")
      product.reload

      first_id = product.images.attachments.first.id
      second_id = product.images.attachments.second.id

      patch admin_product_make_featured_image_path(product, attachment_id: second_id)
      expect(response).to redirect_to(edit_admin_product_path(product))

      product.reload
      expect(product.featured_image_attachment_id.to_i).to eq(second_id)
      expect(product.image_attachment_ids_order.map(&:to_i).first).to eq(second_id)
      expect(product.image_attachment_ids_order.map(&:to_i)).to include(first_id)
    end
  end

  describe "DELETE /admin/products/:id" do
    let(:product) { products.first }

    it "destroys the product" do
      expect {
        delete admin_product_path(product)
      }.to change(Product, :count).by(-1)
    end

    it "redirects to products index" do
      delete admin_product_path(product)
      expect(response).to redirect_to(admin_products_path)
    end
  end
end
