require "rails_helper"

RSpec.describe Supplier, type: :model do
  describe "associations" do
    it { should have_many(:green_coffees).dependent(:destroy) }
  end

  describe "validations" do
    subject { build(:supplier) }

    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:name) }
  end

  describe "scopes" do
    let!(:supplier_b) { create(:supplier, name: "Bravo Imports") }
    let!(:supplier_a) { create(:supplier, name: "Alpha Coffee") }
    let!(:supplier_c) { create(:supplier, name: "Charlie Beans") }

    describe ".alphabetical" do
      it "returns suppliers ordered by name" do
        expect(Supplier.alphabetical).to eq([ supplier_a, supplier_b, supplier_c ])
      end
    end
  end

  describe "#to_s" do
    it "returns the supplier name" do
      supplier = build(:supplier, name: "Royal Coffee")
      expect(supplier.to_s).to eq("Royal Coffee")
    end
  end

  describe "#green_coffee_count" do
    it "returns the number of green coffees" do
      supplier = create(:supplier)
      create_list(:green_coffee, 3, supplier: supplier)
      expect(supplier.green_coffee_count).to eq(3)
    end

    it "returns 0 when no green coffees exist" do
      supplier = create(:supplier)
      expect(supplier.green_coffee_count).to eq(0)
    end
  end

  describe "#total_green_inventory_lbs" do
    it "sums all green coffee quantities" do
      supplier = create(:supplier)
      create(:green_coffee, supplier: supplier, quantity_lbs: 50.0)
      create(:green_coffee, supplier: supplier, quantity_lbs: 30.0)
      expect(supplier.total_green_inventory_lbs).to eq(80.0)
    end

    it "returns 0 when no green coffees exist" do
      supplier = create(:supplier)
      expect(supplier.total_green_inventory_lbs).to eq(0)
    end
  end

  describe "#total_spend" do
    it "sums cost_per_lb * quantity_lbs for all green coffees" do
      supplier = create(:supplier)
      create(:green_coffee, supplier: supplier, cost_per_lb: 5.00, quantity_lbs: 10.0)
      create(:green_coffee, supplier: supplier, cost_per_lb: 8.00, quantity_lbs: 20.0)
      expect(supplier.total_spend).to eq(210.0) # (5*10) + (8*20)
    end
  end
end
