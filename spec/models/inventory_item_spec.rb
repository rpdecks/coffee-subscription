require 'rails_helper'

RSpec.describe InventoryItem, type: :model do
  let(:product) { create(:product, product_type: :coffee) }

  describe "associations" do
    it { should belong_to(:product) }
  end

  describe "validations" do
    it { should validate_presence_of(:quantity) }
    it { should validate_presence_of(:state) }
    it { should validate_numericality_of(:quantity).is_greater_than_or_equal_to(0) }
  end

  describe "enums" do
    it { should define_enum_for(:state).with_values(green: 0, roasted: 1, packaged: 2) }
  end

  describe "scopes" do
    let!(:green_item) { create(:inventory_item, product: product, state: :green, quantity: 10) }
    let!(:roasted_item) { create(:inventory_item, product: product, state: :roasted, quantity: 5) }
    let!(:packaged_item) { create(:inventory_item, product: product, state: :packaged, quantity: 2) }
    let!(:low_stock_item) { create(:inventory_item, product: product, state: :green, quantity: 3) }
    let!(:out_of_stock_item) { create(:inventory_item, product: product, state: :green, quantity: 0) }

    it "filters by state" do
      expect(InventoryItem.green).to include(green_item, low_stock_item, out_of_stock_item)
      expect(InventoryItem.roasted).to eq([ roasted_item ])
      expect(InventoryItem.packaged).to eq([ packaged_item ])
    end

    it "filters available items" do
      expect(InventoryItem.available).to include(green_item, roasted_item, packaged_item, low_stock_item)
      expect(InventoryItem.available).not_to include(out_of_stock_item)
    end

    it "filters low stock items" do
      expect(InventoryItem.low_stock).to include(low_stock_item, packaged_item)
      expect(InventoryItem.low_stock).not_to include(green_item, roasted_item)
    end

    it "filters out of stock items" do
      expect(InventoryItem.out_of_stock).to eq([ out_of_stock_item ])
    end
  end

  describe "#days_since_roast" do
    it "returns nil when roasted_on is nil" do
      item = build(:inventory_item, roasted_on: nil)
      expect(item.days_since_roast).to be_nil
    end

    it "calculates days since roast" do
      item = build(:inventory_item, roasted_on: 5.days.ago.to_date)
      expect(item.days_since_roast).to eq(5)
    end
  end

  describe "#is_fresh?" do
    it "returns true for items without roast date" do
      item = build(:inventory_item, roasted_on: nil)
      expect(item.is_fresh?).to be true
    end

    it "returns true for items roasted within 21 days" do
      item = build(:inventory_item, roasted_on: 10.days.ago.to_date)
      expect(item.is_fresh?).to be true
    end

    it "returns false for items roasted more than 21 days ago" do
      item = build(:inventory_item, roasted_on: 30.days.ago.to_date)
      expect(item.is_fresh?).to be false
    end
  end

  describe "#display_name" do
    it "includes product name and state for coffee" do
      item = create(:inventory_item, product: product, state: :roasted)
      expect(item.display_name).to include(product.name)
      expect(item.display_name).to include("Roasted")
    end

    it "includes lot number when present" do
      item = create(:inventory_item, product: product, lot_number: "LOT123")
      expect(item.display_name).to include("LOT123")
    end
  end

  describe "coffee-specific validations" do
    context "when state is roasted" do
      it "requires roasted_on date for coffee products" do
        item = build(:inventory_item, product: product, state: :roasted, roasted_on: nil)
        expect(item).not_to be_valid
        expect(item.errors[:roasted_on]).to include("must be present for roasted coffee")
      end
    end

    context "when state is green" do
      it "validates received_on should be present" do
        item = build(:inventory_item, product: product, state: :green, received_on: nil)
        expect(item).not_to be_valid
        expect(item.errors[:received_on]).to include("should be present for green coffee")
      end
    end
  end
end
