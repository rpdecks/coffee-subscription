require 'rails_helper'

RSpec.describe Order, type: :model do
  describe "validations" do
    it "requires order_number after creation" do
      order = build(:order, order_number: nil)
      order.save
      expect(order.order_number).to be_present
    end

    it { is_expected.to validate_presence_of(:order_type) }
    it { is_expected.to validate_presence_of(:status) }

    it "validates uniqueness of order_number" do
      order1 = create(:order)
      order2 = build(:order, order_number: order1.order_number)
      expect(order2).not_to be_valid
      expect(order2.errors[:order_number]).to include("has already been taken")
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:subscription).optional }
    it { is_expected.to belong_to(:shipping_address).class_name('Address') }
    it { is_expected.to belong_to(:payment_method).optional }
    it { is_expected.to have_many(:order_items) }
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:order_type).with_values(subscription: 0, one_time: 1) }
    it { is_expected.to define_enum_for(:status).with_values(
      pending: 0, processing: 1, roasting: 2, shipped: 3, delivered: 4, cancelled: 5
    ) }
  end

  describe "callbacks" do
    it "generates order number on create" do
      order = build(:order, order_number: nil)
      order.save
      expect(order.order_number).to be_present
      expect(order.order_number).to match(/^ORD-\d+-[A-F0-9]{6}$/)
    end

    it "does not overwrite existing order number" do
      order = build(:order, order_number: "ORD-CUSTOM-123")
      order.save
      expect(order.order_number).to eq("ORD-CUSTOM-123")
    end
  end

  describe "scopes" do
    let!(:old_order) { create(:order, created_at: 2.days.ago) }
    let!(:new_order) { create(:order, created_at: 1.day.ago) }

    describe ".recent" do
      it "orders by created_at descending" do
        expect(Order.recent.first).to eq(new_order)
        expect(Order.recent.last).to eq(old_order)
      end
    end

    describe ".pending_fulfillment" do
      let!(:pending_order) { create(:order, status: :pending) }
      let!(:processing_order) { create(:order, status: :processing) }
      let!(:roasting_order) { create(:order, status: :roasting) }
      let!(:shipped_order) { create(:order, status: :shipped) }

      it "includes pending, processing, and roasting orders" do
        orders = Order.pending_fulfillment
        expect(orders).to include(pending_order, processing_order, roasting_order)
        expect(orders).not_to include(shipped_order)
      end
    end
  end

  describe "#total" do
    it "converts total_cents to dollars" do
      order = build(:order, total_cents: 2550)
      expect(order.total).to eq(25.50)
    end

    it "returns 0.0 when total_cents is nil" do
      order = build(:order, total_cents: nil)
      expect(order.total).to eq(0.0)
    end
  end

  describe "#subtotal" do
    it "converts subtotal_cents to dollars" do
      order = build(:order, subtotal_cents: 2000)
      expect(order.subtotal).to eq(20.00)
    end
  end

  describe "#shipping" do
    it "converts shipping_cents to dollars" do
      order = build(:order, shipping_cents: 500)
      expect(order.shipping).to eq(5.00)
    end
  end

  describe "#tax" do
    it "converts tax_cents to dollars" do
      order = build(:order, tax_cents: 150)
      expect(order.tax).to eq(1.50)
    end
  end

  describe "#calculate_totals" do
    let(:order) { create(:order, subtotal_cents: 0, shipping_cents: nil, tax_cents: nil, total_cents: 0) }

    before do
      create(:order_item, order: order, quantity: 2, price_cents: 1500)  # $15 x 2 = $30
      create(:order_item, order: order, quantity: 1, price_cents: 1000)  # $10 x 1 = $10
    end

    it "calculates subtotal from order items" do
      order.calculate_totals
      expect(order.subtotal_cents).to eq(4000)  # $40
    end

    it "calculates total including shipping and tax" do
      order.shipping_cents = 500  # $5
      order.tax_cents = 200       # $2
      order.calculate_totals
      expect(order.total_cents).to eq(4700)  # $47
    end

    it "defaults shipping and tax to 0 if nil" do
      order.calculate_totals
      expect(order.shipping_cents).to eq(0)
      expect(order.tax_cents).to eq(0)
      expect(order.total_cents).to eq(4000)
    end
  end
end
