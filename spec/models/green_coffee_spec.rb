require "rails_helper"

RSpec.describe GreenCoffee, type: :model do
  describe "associations" do
    it { should belong_to(:supplier) }
    it { should have_many(:blend_components).dependent(:destroy) }
    it { should have_many(:products).through(:blend_components) }
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_numericality_of(:quantity_lbs).is_greater_than_or_equal_to(0) }
    it { should validate_numericality_of(:cost_per_lb).is_greater_than(0).allow_nil }
  end

  describe "scopes" do
    let(:supplier) { create(:supplier) }
    let!(:in_stock) { create(:green_coffee, supplier: supplier, quantity_lbs: 50.0) }
    let!(:out_of_stock) { create(:green_coffee, supplier: supplier, quantity_lbs: 0.0) }

    describe ".in_stock" do
      it "returns green coffees with positive quantity" do
        expect(GreenCoffee.in_stock).to include(in_stock)
        expect(GreenCoffee.in_stock).not_to include(out_of_stock)
      end
    end

    describe ".out_of_stock" do
      it "returns green coffees with zero quantity" do
        expect(GreenCoffee.out_of_stock).to include(out_of_stock)
        expect(GreenCoffee.out_of_stock).not_to include(in_stock)
      end
    end

    describe ".by_supplier" do
      let(:other_supplier) { create(:supplier) }
      let!(:other_green) { create(:green_coffee, supplier: other_supplier) }

      it "filters by supplier_id" do
        results = GreenCoffee.by_supplier(supplier.id)
        expect(results).to include(in_stock, out_of_stock)
        expect(results).not_to include(other_green)
      end
    end
  end

  describe "#to_s" do
    it "returns the name" do
      gc = build(:green_coffee, name: "Ethiopia Yirgacheffe")
      expect(gc.to_s).to eq("Ethiopia Yirgacheffe")
    end
  end

  describe "#months_since_harvest" do
    it "returns nil when harvest_date is nil" do
      gc = build(:green_coffee, harvest_date: nil)
      expect(gc.months_since_harvest).to be_nil
    end

    it "calculates months since harvest" do
      gc = build(:green_coffee, harvest_date: 6.months.ago.to_date)
      months = gc.months_since_harvest
      expect(months).to be_between(5.5, 6.5)
    end
  end

  describe "#days_since_arrival" do
    it "returns nil when arrived_on is nil" do
      gc = build(:green_coffee, arrived_on: nil)
      expect(gc.days_since_arrival).to be_nil
    end

    it "calculates days since arrival" do
      gc = build(:green_coffee, arrived_on: 10.days.ago.to_date)
      expect(gc.days_since_arrival).to eq(10)
    end
  end

  describe "#freshness_status" do
    it "returns 'fresh' for recently harvested coffee" do
      gc = build(:green_coffee, :fresh)
      expect(gc.freshness_status).to eq("fresh")
    end

    it "returns 'good' for coffee harvested 6-10 months ago" do
      gc = build(:green_coffee, :good)
      expect(gc.freshness_status).to eq("good")
    end

    it "returns 'aging' for coffee harvested 10-12 months ago" do
      gc = build(:green_coffee, :aging)
      expect(gc.freshness_status).to eq("aging")
    end

    it "returns 'past_crop' for coffee harvested over 12 months ago" do
      gc = build(:green_coffee, :past_crop)
      expect(gc.freshness_status).to eq("past_crop")
    end

    it "returns 'unknown' when harvest_date is nil" do
      gc = build(:green_coffee, :no_harvest_date)
      expect(gc.freshness_status).to eq("unknown")
    end
  end

  describe "#fresh?" do
    it "returns true for fresh coffee" do
      gc = build(:green_coffee, :fresh)
      expect(gc.fresh?).to be true
    end

    it "returns false for aging coffee" do
      gc = build(:green_coffee, :aging)
      expect(gc.fresh?).to be false
    end
  end

  describe "#past_crop?" do
    it "returns true for past crop coffee" do
      gc = build(:green_coffee, :past_crop)
      expect(gc.past_crop?).to be true
    end

    it "returns false for fresh coffee" do
      gc = build(:green_coffee, :fresh)
      expect(gc.past_crop?).to be false
    end
  end

  describe "#total_cost" do
    it "returns cost_per_lb * quantity_lbs" do
      gc = build(:green_coffee, cost_per_lb: 6.50, quantity_lbs: 20.0)
      expect(gc.total_cost).to eq(130.0)
    end

    it "returns nil when cost_per_lb is nil" do
      gc = build(:green_coffee, cost_per_lb: nil)
      expect(gc.total_cost).to be_nil
    end
  end

  describe "#display_origin" do
    it "combines country and region" do
      gc = build(:green_coffee, origin_country: "Ethiopia", region: "Yirgacheffe")
      expect(gc.display_origin).to eq("Ethiopia, Yirgacheffe")
    end

    it "returns just country when region is blank" do
      gc = build(:green_coffee, origin_country: "Brazil", region: nil)
      expect(gc.display_origin).to eq("Brazil")
    end

    it "returns empty string when both are blank" do
      gc = build(:green_coffee, origin_country: nil, region: nil)
      expect(gc.display_origin).to eq("")
    end
  end

  describe "#display_details" do
    it "combines variety and process" do
      gc = build(:green_coffee, variety: "Heirloom", process: "Washed")
      expect(gc.display_details).to eq("Heirloom / Washed")
    end

    it "returns just variety when process is blank" do
      gc = build(:green_coffee, variety: "Bourbon", process: nil)
      expect(gc.display_details).to eq("Bourbon")
    end
  end
end
