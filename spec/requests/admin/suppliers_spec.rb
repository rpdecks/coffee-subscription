# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::Suppliers", type: :request do
  let(:admin) { create(:admin_user) }

  before { sign_in admin, scope: :user }

  describe "GET /admin/suppliers" do
    let!(:suppliers) { create_list(:supplier, 3) }

    it "returns http success" do
      get admin_suppliers_path
      expect(response).to have_http_status(:success)
    end

    it "displays all suppliers" do
      get admin_suppliers_path
      suppliers.each do |supplier|
        expect(response.body).to include(supplier.name)
      end
    end

    context "with search" do
      let!(:royal) { create(:supplier, name: "Royal Coffee") }
      let!(:cafe) { create(:supplier, name: "Cafe Imports") }

      it "filters by name" do
        get admin_suppliers_path, params: { search: "Royal" }
        expect(response.body).to include("Royal Coffee")
      end
    end

    context "with pagination" do
      before { create_list(:supplier, 30) }

      it "paginates results" do
        get admin_suppliers_path
        expect(response.body).to include("Showing")
      end
    end
  end

  describe "GET /admin/suppliers/:id" do
    let(:supplier) { create(:supplier) }

    it "returns http success" do
      get admin_supplier_path(supplier)
      expect(response).to have_http_status(:success)
    end

    it "displays supplier details" do
      get admin_supplier_path(supplier)
      expect(response.body).to include(supplier.name)
    end

    context "with green coffees" do
      let!(:green_coffee) { create(:green_coffee, supplier: supplier) }

      it "displays associated green coffees" do
        get admin_supplier_path(supplier)
        expect(response.body).to include(green_coffee.name)
      end
    end
  end

  describe "GET /admin/suppliers/new" do
    it "returns http success" do
      get new_admin_supplier_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /admin/suppliers" do
    let(:valid_attributes) do
      {
        name: "Royal Coffee New York",
        url: "https://royalcoffee.com",
        contact_name: "John",
        contact_email: "john@royalcoffee.com",
        notes: "Great selection"
      }
    end

    it "creates a new supplier" do
      expect {
        post admin_suppliers_path, params: { supplier: valid_attributes }
      }.to change(Supplier, :count).by(1)
    end

    it "redirects to supplier show page" do
      post admin_suppliers_path, params: { supplier: valid_attributes }
      expect(response).to redirect_to(admin_supplier_path(Supplier.last))
    end

    context "with invalid attributes" do
      it "does not create a supplier without a name" do
        expect {
          post admin_suppliers_path, params: { supplier: { name: "" } }
        }.not_to change(Supplier, :count)
      end

      it "renders new with unprocessable status" do
        post admin_suppliers_path, params: { supplier: { name: "" } }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "GET /admin/suppliers/:id/edit" do
    let(:supplier) { create(:supplier) }

    it "returns http success" do
      get edit_admin_supplier_path(supplier)
      expect(response).to have_http_status(:success)
    end
  end

  describe "PATCH /admin/suppliers/:id" do
    let(:supplier) { create(:supplier) }

    it "updates the supplier" do
      patch admin_supplier_path(supplier), params: { supplier: { name: "Updated Name" } }
      expect(supplier.reload.name).to eq("Updated Name")
    end

    it "redirects to supplier show page" do
      patch admin_supplier_path(supplier), params: { supplier: { name: "Updated Name" } }
      expect(response).to redirect_to(admin_supplier_path(supplier))
    end

    context "with invalid attributes" do
      it "renders edit with unprocessable status" do
        patch admin_supplier_path(supplier), params: { supplier: { name: "" } }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "DELETE /admin/suppliers/:id" do
    let!(:supplier) { create(:supplier) }

    it "destroys the supplier" do
      expect {
        delete admin_supplier_path(supplier)
      }.to change(Supplier, :count).by(-1)
    end

    it "redirects to suppliers index" do
      delete admin_supplier_path(supplier)
      expect(response).to redirect_to(admin_suppliers_path)
    end

    context "when supplier has green coffees" do
      before { create(:green_coffee, supplier: supplier) }

      it "also destroys associated green coffees" do
        expect {
          delete admin_supplier_path(supplier)
        }.to change(GreenCoffee, :count).by(-1)
      end
    end
  end
end
