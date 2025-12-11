require 'rails_helper'

RSpec.describe OrderItem, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:quantity) }
    it { is_expected.to validate_presence_of(:price_cents) }
    it { is_expected.to validate_numericality_of(:quantity).is_greater_than(0) }
    it { is_expected.to validate_numericality_of(:price_cents).is_greater_than(0) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:order) }
    it { is_expected.to belong_to(:product) }
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:grind_type).with_values(
      whole_bean: 0, coarse: 1, medium_grind: 2, fine: 3, espresso: 4
    ) }
  end

  describe "callbacks" do
    let(:product) { create(:product, price_cents: 1500) }

    it "sets price from product on create" do
      order_item = build(:order_item, product: product, price_cents: nil)
      order_item.save
      expect(order_item.price_cents).to eq(1500)
    end

    it "does not overwrite existing price" do
      order_item = build(:order_item, product: product, price_cents: 2000)
      order_item.save
      expect(order_item.price_cents).to eq(2000)
    end
  end

  describe "#total_cents" do
    it "multiplies quantity by price_cents" do
      order_item = build(:order_item, quantity: 3, price_cents: 1500)
      expect(order_item.total_cents).to eq(4500)
    end
  end

  describe "#total" do
    it "converts total_cents to dollars" do
      order_item = build(:order_item, quantity: 2, price_cents: 1250)
      expect(order_item.total).to eq(25.00)
    end
  end

  describe "#price" do
    it "converts price_cents to dollars" do
      order_item = build(:order_item, price_cents: 1599)
      expect(order_item.price).to eq(15.99)
    end
  end
end
