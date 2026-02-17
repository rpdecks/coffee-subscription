require "rails_helper"

RSpec.describe BlendComponent, type: :model do
  describe "associations" do
    it { should belong_to(:product) }
    it { should belong_to(:green_coffee) }
  end

  describe "validations" do
    it { should validate_presence_of(:percentage) }
    it { should validate_numericality_of(:percentage).is_greater_than(0).is_less_than_or_equal_to(100) }

    describe "uniqueness of green_coffee per product" do
      let(:product) { create(:product) }
      let(:green_coffee) { create(:green_coffee) }

      before { create(:blend_component, product: product, green_coffee: green_coffee, percentage: 50) }

      it "prevents duplicate green coffee in same product" do
        duplicate = build(:blend_component, product: product, green_coffee: green_coffee, percentage: 50)
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:green_coffee_id]).to include("is already part of this blend")
      end

      it "allows same green coffee in different products" do
        other_product = create(:product)
        component = build(:blend_component, product: other_product, green_coffee: green_coffee, percentage: 50)
        expect(component).to be_valid
      end
    end

    describe "total percentage validation" do
      let(:product) { create(:product) }
      let(:gc1) { create(:green_coffee) }
      let(:gc2) { create(:green_coffee) }
      let(:gc3) { create(:green_coffee) }

      it "allows components that total 100%" do
        create(:blend_component, product: product, green_coffee: gc1, percentage: 60)
        component = build(:blend_component, product: product, green_coffee: gc2, percentage: 40)
        expect(component).to be_valid
      end

      it "rejects components that would exceed 100%" do
        create(:blend_component, product: product, green_coffee: gc1, percentage: 60)
        component = build(:blend_component, product: product, green_coffee: gc2, percentage: 50)
        expect(component).not_to be_valid
        expect(component.errors[:percentage]).to include(a_string_matching(/total cannot exceed 100%/))
      end

      it "allows updating without counting self" do
        component = create(:blend_component, product: product, green_coffee: gc1, percentage: 60)
        create(:blend_component, product: product, green_coffee: gc2, percentage: 30)
        component.percentage = 70
        expect(component).to be_valid
      end
    end
  end

  describe "scopes" do
    describe ".by_percentage" do
      let(:product) { create(:product) }
      let!(:small) { create(:blend_component, product: product, green_coffee: create(:green_coffee), percentage: 20) }
      let!(:large) { create(:blend_component, product: product, green_coffee: create(:green_coffee), percentage: 80) }

      it "orders by percentage descending" do
        expect(BlendComponent.by_percentage).to eq([ large, small ])
      end
    end
  end

  describe "#to_s" do
    it "returns name with percentage" do
      gc = build(:green_coffee, name: "Ethiopia Yirgacheffe")
      component = build(:blend_component, green_coffee: gc, percentage: 60)
      expect(component.to_s).to eq("Ethiopia Yirgacheffe (60.0%)")
    end
  end
end
