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
    let!(:green_item) { create(:inventory_item, product: product, state: :green, quantity: 10, received_on: Date.today) }
    let!(:roasted_item) { create(:inventory_item, product: product, state: :roasted, quantity: 5, roasted_on: Date.today) }
    let!(:packaged_item) { create(:inventory_item, product: product, state: :packaged, quantity: 2, roasted_on: Date.today) }
    let!(:low_stock_item) { create(:inventory_item, product: product, state: :green, quantity: 3, received_on: Date.today) }
    let!(:out_of_stock_item) { create(:inventory_item, product: product, state: :green, quantity: 0, received_on: Date.today) }

    it "filters by state" do
      green_items = InventoryItem.green.where(product: product)
      expect(green_items).to include(green_item, low_stock_item, out_of_stock_item)
      expect(InventoryItem.roasted.where(product: product)).to eq([ roasted_item ])
      expect(InventoryItem.packaged.where(product: product)).to eq([ packaged_item ])
    end

    it "filters available items" do
      available = InventoryItem.available.where(product: product)
      expect(available).to include(green_item, roasted_item, packaged_item, low_stock_item)
      expect(available).not_to include(out_of_stock_item)
    end

    it "filters low stock items" do
      low_stock = InventoryItem.low_stock.where(product: product)
      expect(low_stock).to include(low_stock_item, packaged_item)
      expect(low_stock).not_to include(green_item, roasted_item, out_of_stock_item)
    end

    it "filters out of stock items" do
      expect(InventoryItem.out_of_stock.where(product: product)).to eq([ out_of_stock_item ])
    end
  end

  describe "#days_since_roast" do
    it "returns nil when roasted_on is nil" do
      item = build(:inventory_item, roasted_on: nil)
      expect(item.days_since_roast).to be_nil
    end

    it "calculates days since roast" do
      roast_date = 5.days.ago.to_date
      item = build(:inventory_item, roasted_on: roast_date)
      expect(item.days_since_roast).to be >= 4
      expect(item.days_since_roast).to be <= 6
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
      item = create(:inventory_item, product: product, state: :roasted, roasted_on: Date.today)
      expect(item.display_name).to include(product.name)
      expect(item.display_name).to include("Roasted")
    end

    it "includes lot number when present" do
      item = create(:inventory_item, product: product, lot_number: "LOT123", received_on: Date.today)
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

      it "allows roasted coffee with roasted_on date" do
        item = build(:inventory_item, product: product, state: :roasted, roasted_on: Date.today)
        expect(item).to be_valid
      end
    end

    context "when state is green" do
      it "validates received_on should be present" do
        item = build(:inventory_item, product: product, state: :green, received_on: nil)
        expect(item).not_to be_valid
        expect(item.errors[:received_on]).to include("should be present for green coffee")
      end

      it "allows green coffee with received_on date" do
        item = build(:inventory_item, product: product, state: :green, received_on: Date.today)
        expect(item).to be_valid
      end
    end

    context "for merchandise products" do
      let(:merch_product) { create(:product, product_type: :merch) }

      it "does not validate dates for merchandise" do
        item = build(:inventory_item, product: merch_product, state: :packaged, roasted_on: nil, received_on: nil)
        expect(item).to be_valid
      end
    end
  end

  describe "#days_until_expiry" do
    it "returns nil when expires_on is nil" do
      item = build(:inventory_item, expires_on: nil)
      expect(item.days_until_expiry).to be_nil
    end

    it "calculates days until expiry" do
      expiry_date = 10.days.from_now.to_date
      item = build(:inventory_item, expires_on: expiry_date)
      expect(item.days_until_expiry).to be >= 9
      expect(item.days_until_expiry).to be <= 11
    end

    it "returns negative days for expired items" do
      expiry_date = 5.days.ago.to_date
      item = build(:inventory_item, expires_on: expiry_date)
      expect(item.days_until_expiry).to be <= -4
      expect(item.days_until_expiry).to be >= -6
    end
  end

  describe "#is_expiring_soon?" do
    it "returns false when expires_on is nil" do
      item = build(:inventory_item, expires_on: nil)
      expect(item.is_expiring_soon?).to be false
    end

    it "returns true when expiring within 14 days" do
      item = build(:inventory_item, expires_on: 10.days.from_now.to_date)
      expect(item.is_expiring_soon?).to be true
    end

    it "returns false when expiring after 14 days" do
      item = build(:inventory_item, expires_on: 20.days.from_now.to_date)
      expect(item.is_expiring_soon?).to be false
    end

    it "returns true for already expired items" do
      item = build(:inventory_item, expires_on: 1.day.ago.to_date)
      expect(item.is_expiring_soon?).to be true
    end
  end

  describe "scopes with expiring items" do
    let!(:expiring_item) { create(:inventory_item, product: product, expires_on: 7.days.from_now.to_date, received_on: Date.today) }
    let!(:fresh_item) { create(:inventory_item, product: product, expires_on: 30.days.from_now.to_date, received_on: Date.today) }

    it "filters items expiring soon (default 14 days)" do
      expiring = InventoryItem.expiring_soon.where(product: product)
      expect(expiring).to include(expiring_item)
      expect(expiring).not_to include(fresh_item)
    end

    it "can customize expiring soon threshold" do
      # Item expires in 7 days, so threshold of 8 should include it
      expiring = InventoryItem.expiring_soon(8).where(product: product)
      expect(expiring).to include(expiring_item)

      # Threshold of 6 should not include it
      expiring_strict = InventoryItem.expiring_soon(6).where(product: product)
      expect(expiring_strict).not_to include(expiring_item)
    end
  end

  describe "ordering scopes" do
    let!(:oldest) { create(:inventory_item, product: product, created_at: 3.days.ago) }
    let!(:middle) { create(:inventory_item, product: product, created_at: 2.days.ago) }
    let!(:newest) { create(:inventory_item, product: product, created_at: 1.day.ago) }

    it "orders by recent (created_at desc)" do
      expect(InventoryItem.recent).to eq([ newest, middle, oldest ])
    end
  end

  describe "quantity validations" do
    it "allows zero quantity" do
      item = build(:inventory_item, quantity: 0)
      expect(item).to be_valid
    end

    it "does not allow negative quantity" do
      item = build(:inventory_item, quantity: -5)
      expect(item).not_to be_valid
      expect(item.errors[:quantity]).to be_present
    end

    it "allows decimal quantities" do
      item = build(:inventory_item, quantity: 12.5)
      expect(item).to be_valid
    end
  end
end
