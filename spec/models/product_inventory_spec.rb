require 'rails_helper'

RSpec.describe "Product inventory methods", type: :model do
  let(:coffee_product) { create(:product, product_type: :coffee, name: "Test Coffee") }
  let(:merch_product) { create(:product, product_type: :merch, name: "Test Mug") }

  describe "#total_green_inventory" do
    context "for coffee products" do
      it "returns 0 when no inventory items exist" do
        expect(coffee_product.total_green_inventory).to eq(0.0)
      end

      it "sums all green inventory items" do
        create(:inventory_item, :green, product: coffee_product, quantity: 10.0)
        create(:inventory_item, :green, product: coffee_product, quantity: 15.5)
        expect(coffee_product.total_green_inventory).to eq(25.5)
      end

      it "excludes roasted and packaged inventory" do
        create(:inventory_item, :green, product: coffee_product, quantity: 10.0)
        create(:inventory_item, :roasted, product: coffee_product, quantity: 5.0)
        create(:inventory_item, :packaged, product: coffee_product, quantity: 3.0)
        expect(coffee_product.total_green_inventory).to eq(10.0)
      end
    end

    context "for merch products" do
      it "returns 0" do
        create(:inventory_item, product: merch_product, quantity: 10.0)
        expect(merch_product.total_green_inventory).to eq(0.0)
      end
    end
  end

  describe "#total_roasted_inventory" do
    context "for coffee products" do
      it "returns 0 when no roasted inventory exists" do
        expect(coffee_product.total_roasted_inventory).to eq(0.0)
      end

      it "sums all roasted inventory items" do
        create(:inventory_item, :roasted, product: coffee_product, quantity: 8.0)
        create(:inventory_item, :roasted, product: coffee_product, quantity: 12.5)
        expect(coffee_product.total_roasted_inventory).to eq(20.5)
      end

      it "excludes green and packaged inventory" do
        create(:inventory_item, :green, product: coffee_product, quantity: 10.0)
        create(:inventory_item, :roasted, product: coffee_product, quantity: 5.0)
        create(:inventory_item, :packaged, product: coffee_product, quantity: 3.0)
        expect(coffee_product.total_roasted_inventory).to eq(5.0)
      end
    end

    context "for merch products" do
      it "returns 0" do
        create(:inventory_item, product: merch_product, quantity: 10.0)
        expect(merch_product.total_roasted_inventory).to eq(0.0)
      end
    end
  end

  describe "#total_packaged_inventory" do
    it "returns 0 when no packaged inventory exists" do
      expect(coffee_product.total_packaged_inventory).to eq(0.0)
    end

    it "sums all packaged inventory items" do
      create(:inventory_item, :packaged, product: coffee_product, quantity: 6.0)
      create(:inventory_item, :packaged, product: coffee_product, quantity: 4.5)
      expect(coffee_product.total_packaged_inventory).to eq(10.5)
    end

    it "works for both coffee and merch" do
      create(:inventory_item, :packaged, product: coffee_product, quantity: 5.0)
      create(:inventory_item, product: merch_product, state: :packaged, quantity: 10.0)
      expect(coffee_product.total_packaged_inventory).to eq(5.0)
      expect(merch_product.total_packaged_inventory).to eq(10.0)
    end
  end

  describe "#total_inventory_pounds" do
    context "for coffee products" do
      it "returns 0 when no inventory exists" do
        expect(coffee_product.total_inventory_pounds).to eq(0.0)
      end

      it "sums green, roasted, and packaged inventory" do
        create(:inventory_item, :green, product: coffee_product, quantity: 20.0)
        create(:inventory_item, :roasted, product: coffee_product, quantity: 10.0)
        create(:inventory_item, :packaged, product: coffee_product, quantity: 5.0)
        expect(coffee_product.total_inventory_pounds).to eq(35.0)
      end

      it "includes multiple items of the same state" do
        create(:inventory_item, :green, product: coffee_product, quantity: 10.0)
        create(:inventory_item, :green, product: coffee_product, quantity: 15.0)
        create(:inventory_item, :roasted, product: coffee_product, quantity: 8.0)
        expect(coffee_product.total_inventory_pounds).to eq(33.0)
      end
    end

    context "for merch products" do
      it "sums all inventory regardless of state" do
        create(:inventory_item, product: merch_product, state: :packaged, quantity: 25.0)
        create(:inventory_item, product: merch_product, state: :packaged, quantity: 15.0)
        expect(merch_product.total_inventory_pounds).to eq(40.0)
      end
    end
  end

  describe "#low_on_inventory?" do
    it "returns true when total inventory is below threshold" do
      create(:inventory_item, product: coffee_product, quantity: 3.0)
      expect(coffee_product.low_on_inventory?(5.0)).to be true
    end

    it "returns false when total inventory is above threshold" do
      create(:inventory_item, product: coffee_product, quantity: 10.0)
      expect(coffee_product.low_on_inventory?(5.0)).to be false
    end

    it "uses default threshold of 5.0" do
      create(:inventory_item, product: coffee_product, quantity: 3.0)
      expect(coffee_product.low_on_inventory?).to be true
    end

    it "returns false when exactly at threshold" do
      create(:inventory_item, product: coffee_product, quantity: 5.0)
      expect(coffee_product.low_on_inventory?(5.0)).to be false
    end

    it "sums all states for coffee" do
      create(:inventory_item, :green, product: coffee_product, quantity: 2.0)
      create(:inventory_item, :roasted, product: coffee_product, quantity: 2.0)
      expect(coffee_product.low_on_inventory?(5.0)).to be true
      expect(coffee_product.low_on_inventory?(4.0)).to be false
    end
  end

  describe "#fresh_roasted_inventory" do
    context "for coffee products" do
      it "returns 0 when no roasted inventory exists" do
        expect(coffee_product.fresh_roasted_inventory).to eq(0.0)
      end

      it "includes roasted coffee within 21 days" do
        create(:inventory_item, :roasted, product: coffee_product, quantity: 10.0, roasted_on: 5.days.ago.to_date)
        create(:inventory_item, :roasted, product: coffee_product, quantity: 8.0, roasted_on: 15.days.ago.to_date)
        expect(coffee_product.fresh_roasted_inventory).to eq(18.0)
      end

      it "excludes roasted coffee older than 21 days" do
        create(:inventory_item, :roasted, product: coffee_product, quantity: 10.0, roasted_on: 5.days.ago.to_date)
        create(:inventory_item, :roasted, product: coffee_product, quantity: 8.0, roasted_on: 30.days.ago.to_date)
        expect(coffee_product.fresh_roasted_inventory).to eq(10.0)
      end

      it "excludes green and packaged inventory" do
        create(:inventory_item, :green, product: coffee_product, quantity: 20.0)
        create(:inventory_item, :roasted, product: coffee_product, quantity: 10.0, roasted_on: 5.days.ago.to_date)
        create(:inventory_item, :packaged, product: coffee_product, quantity: 5.0)
        expect(coffee_product.fresh_roasted_inventory).to eq(10.0)
      end

      it "handles exactly 21 days old" do
        create(:inventory_item, :roasted, product: coffee_product, quantity: 10.0, roasted_on: 21.days.ago.to_date)
        expect(coffee_product.fresh_roasted_inventory).to eq(10.0)
      end

      it "excludes 22 days old" do
        # Use Date arithmetic instead of time arithmetic to avoid precision issues
        roast_date = Date.today - 22
        create(:inventory_item, :roasted, product: coffee_product, quantity: 10.0, roasted_on: roast_date)
        expect(coffee_product.fresh_roasted_inventory).to eq(0.0)
      end
    end

    context "for merch products" do
      it "returns 0" do
        create(:inventory_item, product: merch_product, quantity: 10.0)
        expect(merch_product.fresh_roasted_inventory).to eq(0.0)
      end
    end
  end

  describe "inventory associations" do
    it "has many inventory items" do
      expect(coffee_product).to respond_to(:inventory_items)
    end

    it "destroys inventory items when product is destroyed" do
      create(:inventory_item, product: coffee_product)
      create(:inventory_item, product: coffee_product)
      expect {
        coffee_product.destroy
      }.to change(InventoryItem, :count).by(-2)
    end

    it "properly associates inventory items" do
      item1 = create(:inventory_item, product: coffee_product)
      item2 = create(:inventory_item, product: coffee_product)
      expect(coffee_product.inventory_items).to match_array([ item1, item2 ])
    end
  end

  describe "complex inventory scenarios" do
    context "mixed inventory states" do
      before do
        # Green coffee
        create(:inventory_item, :green, product: coffee_product, quantity: 50.0)
        create(:inventory_item, :green, product: coffee_product, quantity: 30.0)

        # Fresh roasted
        create(:inventory_item, :roasted, product: coffee_product, quantity: 12.0, roasted_on: 3.days.ago.to_date)
        create(:inventory_item, :roasted, product: coffee_product, quantity: 8.0, roasted_on: 10.days.ago.to_date)

        # Aging roasted
        create(:inventory_item, :roasted, product: coffee_product, quantity: 5.0, roasted_on: 25.days.ago.to_date)

        # Packaged
        create(:inventory_item, :packaged, product: coffee_product, quantity: 15.0)
      end

      it "calculates total correctly" do
        expect(coffee_product.total_inventory_pounds).to eq(120.0)
      end

      it "calculates fresh roasted correctly" do
        expect(coffee_product.fresh_roasted_inventory).to eq(20.0)
      end

      it "calculates each state correctly" do
        expect(coffee_product.total_green_inventory).to eq(80.0)
        expect(coffee_product.total_roasted_inventory).to eq(25.0)
        expect(coffee_product.total_packaged_inventory).to eq(15.0)
      end
    end

    context "multiple products" do
      let(:another_coffee) { create(:product, product_type: :coffee, name: "Another Coffee") }

      before do
        create(:inventory_item, :green, product: coffee_product, quantity: 20.0)
        create(:inventory_item, :green, product: another_coffee, quantity: 30.0)
      end

      it "tracks inventory separately per product" do
        expect(coffee_product.total_green_inventory).to eq(20.0)
        expect(another_coffee.total_green_inventory).to eq(30.0)
      end
    end

    context "zero and negative edge cases" do
      it "handles zero quantity items" do
        create(:inventory_item, product: coffee_product, quantity: 0.0)
        expect(coffee_product.total_inventory_pounds).to eq(0.0)
      end

      it "handles mix of zero and positive quantities" do
        create(:inventory_item, :green, product: coffee_product, quantity: 10.0)
        create(:inventory_item, :roasted, product: coffee_product, quantity: 0.0)
        expect(coffee_product.total_inventory_pounds).to eq(10.0)
      end
    end
  end
end
