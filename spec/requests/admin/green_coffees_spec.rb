# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::GreenCoffees", type: :request do
  let(:admin) { create(:admin_user) }
  let(:supplier) { create(:supplier) }

  before { sign_in admin, scope: :user }

  describe "GET /admin/green_coffees" do
    let!(:green_coffees) { create_list(:green_coffee, 3, supplier: supplier) }

    it "returns http success" do
      get admin_green_coffees_path
      expect(response).to have_http_status(:success)
    end

    it "displays all green coffees" do
      get admin_green_coffees_path
      green_coffees.each do |gc|
        expect(response.body).to include(gc.name)
      end
    end

    it "displays summary statistics" do
      get admin_green_coffees_path
      expect(response.body).to include("Total Inventory")
    end

    context "with search" do
      let!(:ethiopian) { create(:green_coffee, supplier: supplier, name: "Ethiopia Sidamo", origin_country: "Ethiopia") }

      it "filters by name" do
        get admin_green_coffees_path, params: { search: "Sidamo" }
        expect(response.body).to include("Ethiopia Sidamo")
      end

      it "filters by origin country" do
        get admin_green_coffees_path, params: { search: "Ethiopia" }
        expect(response.body).to include("Ethiopia Sidamo")
      end
    end

    context "with supplier filter" do
      let(:other_supplier) { create(:supplier) }
      let!(:other_gc) { create(:green_coffee, supplier: other_supplier, name: "Colombia Huila") }

      it "filters by supplier" do
        get admin_green_coffees_path, params: { supplier_id: supplier.id }
        green_coffees.each do |gc|
          expect(response.body).to include(gc.name)
        end
        expect(response.body).not_to include("Colombia Huila")
      end
    end

    context "with stock filter" do
      let!(:stocked) { create(:green_coffee, supplier: supplier, name: "In Stock GC", quantity_lbs: 50) }
      let!(:empty) { create(:green_coffee, supplier: supplier, name: "Empty GC", quantity_lbs: 0) }

      it "filters in-stock items" do
        get admin_green_coffees_path, params: { stock: "in_stock" }
        expect(response.body).to include("In Stock GC")
        expect(response.body).not_to include("Empty GC")
      end

      it "filters out-of-stock items" do
        get admin_green_coffees_path, params: { stock: "out_of_stock" }
        expect(response.body).to include("Empty GC")
        expect(response.body).not_to include("In Stock GC")
      end
    end

    context "with pagination" do
      before { create_list(:green_coffee, 30, supplier: supplier) }

      it "paginates results" do
        get admin_green_coffees_path
        expect(response.body).to include("Showing")
      end
    end
  end

  describe "GET /admin/green_coffees/:id" do
    let(:green_coffee) { create(:green_coffee, supplier: supplier) }

    it "returns http success" do
      get admin_green_coffee_path(green_coffee)
      expect(response).to have_http_status(:success)
    end

    it "displays green coffee details" do
      get admin_green_coffee_path(green_coffee)
      expect(response.body).to include(green_coffee.name)
      expect(response.body).to include(green_coffee.origin_country)
    end

    context "with blend components" do
      let(:product) { create(:product) }
      let!(:component) { create(:blend_component, product: product, green_coffee: green_coffee, percentage: 60) }

      it "displays associated products" do
        get admin_green_coffee_path(green_coffee)
        expect(response.body).to include(product.name)
      end
    end
  end

  describe "GET /admin/green_coffees/new" do
    it "returns http success" do
      get new_admin_green_coffee_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /admin/green_coffees" do
    let(:valid_attributes) do
      {
        supplier_id: supplier.id,
        name: "Ethiopia Yirgacheffe Grade 1",
        origin_country: "Ethiopia",
        region: "Yirgacheffe",
        variety: "Heirloom",
        process: "Washed",
        harvest_date: 3.months.ago.to_date.to_s,
        arrived_on: 1.month.ago.to_date.to_s,
        cost_per_lb: 7.50,
        quantity_lbs: 100,
        lot_number: "ETH-2025-001"
      }
    end

    it "creates a new green coffee" do
      expect {
        post admin_green_coffees_path, params: { green_coffee: valid_attributes }
      }.to change(GreenCoffee, :count).by(1)
    end

    it "redirects to green coffee show page" do
      post admin_green_coffees_path, params: { green_coffee: valid_attributes }
      expect(response).to redirect_to(admin_green_coffee_path(GreenCoffee.last))
    end

    context "with invalid attributes" do
      it "does not create without a name" do
        expect {
          post admin_green_coffees_path, params: { green_coffee: valid_attributes.merge(name: "") }
        }.not_to change(GreenCoffee, :count)
      end

      it "renders new with unprocessable status" do
        post admin_green_coffees_path, params: { green_coffee: valid_attributes.merge(name: "") }
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "does not create with negative quantity" do
        expect {
          post admin_green_coffees_path, params: { green_coffee: valid_attributes.merge(quantity_lbs: -5) }
        }.not_to change(GreenCoffee, :count)
      end
    end
  end

  describe "GET /admin/green_coffees/:id/edit" do
    let(:green_coffee) { create(:green_coffee, supplier: supplier) }

    it "returns http success" do
      get edit_admin_green_coffee_path(green_coffee)
      expect(response).to have_http_status(:success)
    end
  end

  describe "PATCH /admin/green_coffees/:id" do
    let(:green_coffee) { create(:green_coffee, supplier: supplier) }

    it "updates the green coffee" do
      patch admin_green_coffee_path(green_coffee), params: { green_coffee: { name: "Updated Name" } }
      expect(green_coffee.reload.name).to eq("Updated Name")
    end

    it "redirects to green coffee show page" do
      patch admin_green_coffee_path(green_coffee), params: { green_coffee: { name: "Updated Name" } }
      expect(response).to redirect_to(admin_green_coffee_path(green_coffee))
    end

    context "with invalid attributes" do
      it "renders edit with unprocessable status" do
        patch admin_green_coffee_path(green_coffee), params: { green_coffee: { name: "" } }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "DELETE /admin/green_coffees/:id" do
    let!(:green_coffee) { create(:green_coffee, supplier: supplier) }

    it "destroys the green coffee" do
      expect {
        delete admin_green_coffee_path(green_coffee)
      }.to change(GreenCoffee, :count).by(-1)
    end

    it "redirects to green coffees index" do
      delete admin_green_coffee_path(green_coffee)
      expect(response).to redirect_to(admin_green_coffees_path)
    end
  end
end
