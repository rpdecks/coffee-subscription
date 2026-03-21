require "rails_helper"

RSpec.describe RoastAndPackageInventoryRecorder do
  describe ".call" do
    it "records a roast, creates packaged inventory, and debits green coffee" do
      product = create(:product, :coffee, weight_oz: 12)
      green_coffee = create(:green_coffee, quantity_lbs: 40.0)

      result = described_class.call(params: {
        product_id: product.id,
        green_coffee_id: green_coffee.id,
        green_weight_used: 10.0,
        roasted_weight: 8.5,
        packaged_weight: 6.0,
        roasted_on: Date.current,
        lot_number: "SALMO-1",
        batch_id: "BATCH-1",
        notes: "First roast"
      })

      expect(result).to be_success
      expect(result.roasted_item).to be_present
      expect(result.packaged_item).to be_present
      expect(result.green_coffee_debited_lbs.to_f).to eq(10.0)
      expect(green_coffee.reload.quantity_lbs.to_f).to eq(30.0)
      expect(product.reload.total_roasted_inventory.to_f).to eq(2.5)
      expect(product.total_packaged_inventory.to_f).to eq(6.0)
      expect(product.sellable_bag_count).to eq(8)
    end

    it "can package existing roasted inventory without recording a new roast" do
      product = create(:product, :coffee, weight_oz: 12)
      create(:inventory_item, :roasted, product:, quantity: 5.0, roasted_on: Date.current)

      result = described_class.call(params: {
        product_id: product.id,
        packaged_weight: 3.0,
        roasted_on: Date.current,
        lot_number: "SALMO-2"
      })

      expect(result).to be_success
      expect(result.roasted_item).to be_nil
      expect(result.packaged_item).to be_present
      expect(product.reload.total_roasted_inventory.to_f).to eq(2.0)
      expect(product.total_packaged_inventory.to_f).to eq(3.0)
      expect(product.sellable_bag_count).to eq(4)
    end

    it "fails when packaged weight exceeds available roasted inventory" do
      product = create(:product, :coffee, weight_oz: 12)

      result = described_class.call(params: {
        product_id: product.id,
        packaged_weight: 2.0,
        roasted_on: Date.current
      })

      expect(result).not_to be_success
      expect(result.errors).to include("Not enough roasted inventory available to package 2.0 lbs")
    end
  end
end
