# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Admin::Customers", type: :request do
  let(:admin) { create(:admin_user) }
  let!(:customers) { create_list(:customer_user, 5) }

  before do
    sign_in admin, scope: :user
  end

  describe "GET /admin/customers" do
    it "returns http success" do
      get admin_customers_path
      expect(response).to have_http_status(:success)
    end

    it "displays all customers" do
      get admin_customers_path
      customers.each do |customer|
        expect(response.body).to include(customer.email)
      end
    end

    context "with pagination" do
      before { create_list(:customer_user, 30) }

      it "paginates results" do
        get admin_customers_path
        expect(response.body).to include("pagination")
      end
    end

    context "with search" do
      let!(:searchable_customer) { create(:customer_user, email: "searchable@example.com") }

      it "finds customers by email" do
        get admin_customers_path, params: { search: "searchable" }
        expect(response.body).to include("searchable@example.com")
      end

      it "finds customers by name" do
        customer = create(:customer_user, first_name: "Unique", last_name: "Name")
        get admin_customers_path, params: { search: "Unique" }
        expect(response.body).to include("Unique")
      end
    end
  end

  describe "GET /admin/customers/:id" do
    let(:customer) { customers.first }
    let!(:subscription) { create(:subscription, user: customer) }
    let!(:address) { create(:address, user: customer) }

    it "returns http success" do
      get admin_customer_path(customer)
      expect(response).to have_http_status(:success)
    end

    it "displays customer details" do
      get admin_customer_path(customer)
      expect(response.body).to include(customer.email)
      expect(response.body).to include(customer.first_name)
      expect(response.body).to include(customer.last_name)
    end

    it "displays subscription information" do
      get admin_customer_path(customer)
      expect(response.body).to include(subscription.subscription_plan.name)
    end

    it "displays address information" do
      get admin_customer_path(customer)
      expect(response.body).to include(address.street_address)
    end
  end

  describe "GET /admin/customers/export" do
    let!(:customer_with_subscription) { create(:customer_user) }
    let!(:subscription) { create(:subscription, user: customer_with_subscription) }

    it "returns CSV file" do
      get export_admin_customers_path(format: :csv)
      expect(response.content_type).to eq("text/csv")
    end

    it "includes customer data" do
      get export_admin_customers_path(format: :csv)
      csv_data = response.body
      customers.each do |customer|
        expect(csv_data).to include(customer.email)
      end
    end

    it "includes headers" do
      get export_admin_customers_path(format: :csv)
      expect(response.body).to include("ID")
      expect(response.body).to include("Email")
      expect(response.body).to include("Subscriptions")
    end
  end
end
