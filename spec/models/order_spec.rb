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

    describe ".delivered_today" do
      let!(:delivered_today_order) { create(:order, :delivered, delivered_at: Time.zone.now) }
      let!(:older_delivered_order) { create(:order, :delivered, delivered_at: 2.days.ago) }

      it "includes only orders delivered today" do
        expect(Order.delivered_today).to include(delivered_today_order)
        expect(Order.delivered_today).not_to include(older_delivered_order)
      end
    end

    describe ".stale_fulfillment" do
      let!(:stale_order) { create(:order, :pending, created_at: 3.days.ago) }
      let!(:fresh_order) { create(:order, :processing, created_at: 1.day.ago) }
      let!(:shipped_order) { create(:order, :shipped, created_at: 6.days.ago) }

      it "includes only stale fulfillment orders" do
        expect(Order.stale_fulfillment).to include(stale_order)
        expect(Order.stale_fulfillment).not_to include(fresh_order, shipped_order)
      end
    end

    describe ".critical_fulfillment" do
      let!(:critical_order) { create(:order, :roasting, created_at: 6.days.ago) }
      let!(:stale_only_order) { create(:order, :pending, created_at: 3.days.ago) }

      it "includes only critical fulfillment orders" do
        expect(Order.critical_fulfillment).to include(critical_order)
        expect(Order.critical_fulfillment).not_to include(stale_only_order)
      end
    end
  end

  describe "status transitions" do
    it "allows valid forward transitions" do
      order = create(:order, :processing)

      order.status = :roasting

      expect(order).to be_valid
    end

    it "rejects invalid backward transitions" do
      order = create(:order, :delivered)

      order.status = :processing

      expect(order).not_to be_valid
      expect(order.errors[:status]).to include("cannot change from Delivered to Processing")
    end

    it "requires a delivery note for manual deliveries" do
      order = create(:order, :pending)

      order.status = :delivered
      order.tracking_number = nil
      order.delivery_note = nil

      expect(order).not_to be_valid
      expect(order.errors[:delivery_note]).to include("is required when marking an order delivered without tracking")
    end

    it "allows delivered orders without a note when tracking is present" do
      order = create(:order, :shipped, tracking_number: "TRACK123")

      order.status = :delivered
      order.delivery_note = nil

      expect(order).to be_valid
    end
  end

  describe "workflow helpers" do
    it "describes the next fulfillment step for an arbitrary status" do
      expect(Order.next_fulfillment_step_for("delivered")).to eq("Fulfillment complete")
      expect(Order.next_fulfillment_step_for("cancelled")).to eq("Order closed")
    end

    it "returns available admin statuses for the current state" do
      order = create(:order, :roasting)

      expect(order.available_statuses_for_admin).to eq(%w[roasting shipped delivered cancelled])
    end

    it "describes the next fulfillment step" do
      order = build(:order, :pending)

      expect(order.next_fulfillment_step).to eq("Review payment and move into processing")
    end

    it "identifies manual deliveries" do
      expect(build(:order, :delivered, tracking_number: nil)).to be_manual_delivery
      expect(build(:order, :delivered, tracking_number: "TRACK123")).not_to be_manual_delivery
    end

    it "flags stale fulfillment orders" do
      order = create(:order, :pending, created_at: 3.days.ago)

      expect(order.stale_fulfillment?).to be(true)
      expect(order.critical_fulfillment?).to be(false)
      expect(order.fulfillment_age_label).to eq("Needs attention")
    end

    it "flags critical fulfillment orders" do
      order = create(:order, :processing, created_at: 6.days.ago)

      expect(order.critical_fulfillment?).to be(true)
      expect(order.fulfillment_age_label).to eq("Critical aging")
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
