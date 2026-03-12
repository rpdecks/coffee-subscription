# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Admin::Orders", type: :request do
  let(:admin) { create(:admin_user) }
  let(:customer) { create(:customer_user) }
  let(:subscription_plan) { create(:subscription_plan) }
  let(:address) { create(:address, user: customer) }
  let(:subscription) { create(:subscription, user: customer, subscription_plan: subscription_plan) }
  let!(:product) { create(:product) }

  before do
    sign_in admin, scope: :user
  end

  def stripe_payment_intent(id:, customer_id: "cus_test_123", name: "Jane Doe", email: "jane@example.com", phone: "555-123-9999")
    address = OpenStruct.new(
      line1: "123 Main St",
      line2: nil,
      city: "Columbia",
      state: "SC",
      postal_code: "29201",
      country: "US"
    )

    charge = OpenStruct.new(
      id: "ch_test_123",
      billing_details: OpenStruct.new(
        name: name,
        email: email,
        phone: phone,
        address: address
      )
    )

    OpenStruct.new(id: id, customer: customer_id, latest_charge: charge)
  end

  describe "GET /admin/orders" do
    let!(:orders) { create_list(:order, 3, user: customer, subscription: subscription, shipping_address: address) }

    it "returns http success" do
      get admin_orders_path
      expect(response).to have_http_status(:success)
    end

    it "displays all orders" do
      get admin_orders_path
      orders.each do |order|
        expect(response.body).to include(order.order_number)
      end
    end

    context "with pagination" do
      before { create_list(:order, 30, user: customer, subscription: subscription, shipping_address: address) }

      it "paginates results" do
        get admin_orders_path
        expect(response.body).to match(/pagination/i)
        # Check that pagination info is present (from, to, count)
        expect(response.body).to match(/showing.*1.*to.*25.*of.*33/i)
      end

      it "respects per_page limit" do
        get admin_orders_path
        # Pagy default is 25 items, but showing 20 for first page
        expect(response.body).to match(/showing.*1.*to.*\d+.*of.*\d+/i)
      end
    end

    context "with search" do
      let!(:searchable_order) { create(:order, order_number: "ORD-2025-SEARCH", user: customer, subscription: subscription, shipping_address: address) }

      it "finds orders by order number" do
        get admin_orders_path, params: { search: "SEARCH" }
        expect(response.body).to include("ORD-2025-SEARCH")
      end

      it "finds orders by customer email" do
        get admin_orders_path, params: { search: customer.email }
        expect(response.body).to include(customer.email)
      end
    end

    context "with status filter" do
      let!(:shipped_order) { create(:order, :shipped, user: customer, subscription: subscription, shipping_address: address) }
      let!(:delivered_order) { create(:order, :delivered, user: customer, subscription: subscription, shipping_address: address) }

      it "filters by status" do
        get admin_orders_path, params: { status: "shipped" }
        expect(response.body).to include(shipped_order.order_number)
        expect(response.body).not_to include(delivered_order.order_number)
      end
    end

    context "when not logged in as admin" do
      before { sign_out admin }

      it "redirects to sign in" do
        get admin_orders_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when logged in as customer" do
      before do
        sign_out admin
        sign_in customer, scope: :user
      end

      it "redirects to root" do
        get admin_orders_path
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "GET /admin/orders/:id" do
    let(:order) { create(:order, user: customer, subscription: subscription, shipping_address: address) }
    let!(:order_item) { create(:order_item, order: order, product: product) }

    it "returns http success" do
      get admin_order_path(order)
      expect(response).to have_http_status(:success)
    end

    it "displays order details" do
      get admin_order_path(order)
      expect(response.body).to include(order.order_number)
      expect(response.body).to include(customer.email)
      expect(response.body).to include(product.name)
    end

    it "displays shipping address" do
      get admin_order_path(order)
      expect(response.body).to include(address.street_address)
      expect(response.body).to include(address.city)
    end
  end

  describe "GET /admin/orders/new" do
    it "returns http success" do
      get new_admin_order_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Record Manual Sale")
    end
  end

  describe "POST /admin/orders" do
    context "for coffee products" do
      let!(:coffee_product) { create(:product, :coffee, weight_oz: 12, inventory_count: 40, price_cents: 1500) }
      let!(:packaged_inventory) { create(:inventory_item, :packaged, product: coffee_product, quantity: 1.94) }

      before do
        allow(Stripe::PaymentIntent).to receive(:retrieve).and_return(stripe_payment_intent(id: "pi_manual_sale_123"))
      end

      it "creates an order from a Stripe transaction and decrements packaged inventory" do
        expect {
          post admin_orders_path, params: {
            manual_sale: {
              transaction_reference: "pi_manual_sale_123",
              product_id: coffee_product.id,
              quantity: 2,
              status: "delivered"
            }
          }
        }.to change(Order, :count).by(1)

        order = Order.last
        expect(order.order_type).to eq("one_time")
        expect(order.status).to eq("delivered")
        expect(order.stripe_payment_intent_id).to eq("pi_manual_sale_123")
        expect(order.user.email).to eq("jane@example.com")
        expect(order.user.first_name).to eq("Jane")
        expect(order.shipping_address.city).to eq("Columbia")
        expect(order.delivered_at).to be_present
        expect(coffee_product.reload.total_packaged_inventory.to_f).to be_within(0.001).of(0.44)
      end

      it "rejects duplicate Stripe transaction imports" do
        create(:order, :one_time, user: customer, shipping_address: address, stripe_payment_intent_id: "pi_manual_sale_123")

        expect {
          post admin_orders_path, params: {
            manual_sale: {
              transaction_reference: "pi_manual_sale_123",
              product_id: coffee_product.id,
              quantity: 1,
              status: "delivered"
            }
          }
        }.not_to change(Order, :count)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("already been imported")
      end
    end

    context "for merch products without a Stripe transaction" do
      let!(:merch_product) { create(:product, :merch, inventory_count: 5, price_cents: 2400) }

      it "creates an order and decrements inventory_count" do
        expect {
          post admin_orders_path, params: {
            manual_sale: {
              product_id: merch_product.id,
              quantity: 2,
              status: "processing",
              customer_name: "Local Customer",
              customer_email: "local@example.com",
              customer_phone: "555-111-2222",
              street_address: "45 Market St",
              city: "Irmo",
              state: "SC",
              zip_code: "29063",
              country: "US"
            }
          }
        }.to change(Order, :count).by(1)

        order = Order.last
        expect(order.status).to eq("processing")
        expect(order.user.email).to eq("local@example.com")
        expect(merch_product.reload.inventory_count).to eq(3)
        expect(response).to redirect_to(admin_order_path(order))
      end
    end
  end

  describe "PATCH /admin/orders/:id/update_status" do
    let(:order) { create(:order, :pending, user: customer, subscription: subscription, shipping_address: address) }

    it "updates order status" do
      expect {
        patch update_status_admin_order_path(order), params: { status: "processing" }
      }.to change { order.reload.status }.from("pending").to("processing")
    end

    it "redirects to order show page" do
      patch update_status_admin_order_path(order), params: { status: "processing" }
      expect(response).to redirect_to(admin_order_path(order))
    end

    it "sets flash notice" do
      patch update_status_admin_order_path(order), params: { status: "processing" }
      expect(flash[:notice]).to be_present
    end

    context "with email notifications" do
      it "sends confirmation email when processing" do
        expect {
          patch update_status_admin_order_path(order), params: { status: "processing" }
        }.to have_enqueued_mail(OrderMailer, :order_confirmation)
      end

      it "sends roasting email when roasting" do
        expect {
          patch update_status_admin_order_path(order), params: { status: "roasting" }
        }.to have_enqueued_mail(OrderMailer, :order_roasting)
      end

      it "sends shipped email when shipped" do
        expect {
          patch update_status_admin_order_path(order), params: { status: "shipped" }
        }.to have_enqueued_mail(OrderMailer, :order_shipped)
      end

      it "sends delivered email when delivered" do
        expect {
          patch update_status_admin_order_path(order), params: { status: "delivered" }
        }.to have_enqueued_mail(OrderMailer, :order_delivered)
      end
    end
  end

  describe "GET /admin/orders/export" do
    let!(:orders) { create_list(:order, 3, user: customer, subscription: subscription, shipping_address: address) }

    it "returns CSV file" do
      get export_admin_orders_path(format: :csv)
      expect(response.content_type).to match(/text\/csv/)
    end

    it "includes order data" do
      get export_admin_orders_path(format: :csv)
      csv_data = response.body
      orders.each do |order|
        expect(csv_data).to include(order.order_number)
        expect(csv_data).to include(customer.email)
      end
    end

    it "includes headers" do
      get export_admin_orders_path(format: :csv)
      expect(response.body).to include("Order Number")
      expect(response.body).to include("Customer")
      expect(response.body).to include("Status")
    end

    it "respects search filter" do
      searchable_order = create(:order, order_number: "ORD-2025-EXPORT", user: customer, subscription: subscription, shipping_address: address)
      get export_admin_orders_path(format: :csv), params: { search: "EXPORT" }
      expect(response.body).to include("ORD-2025-EXPORT")
    end

    it "respects status filter" do
      shipped_order = create(:order, :shipped, user: customer, subscription: subscription, shipping_address: address)
      get export_admin_orders_path(format: :csv), params: { status: "shipped" }
      expect(response.body).to include(shipped_order.order_number)
    end
  end
end
