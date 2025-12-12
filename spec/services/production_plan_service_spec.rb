require "rails_helper"

RSpec.describe ProductionPlanService, type: :service do
  let(:coffee_product) { create(:product, name: "House Blend", product_type: :coffee) }
  let(:order) { create(:order, :pending) }
  let!(:order_item) { create(:order_item, order: order, product: coffee_product, quantity: 4) }
  let!(:inventory_item) { create(:inventory_item, :roasted, product: coffee_product, quantity: 1.5) }

  subject(:plan) { described_class.call }

  it "returns a plan result" do
    expect(plan).to be_a(ProductionPlanService::Result)
    expect(plan.reference_date).to be_a(Date)
    expect(plan.plan_entries).to be_an(Array)
  end

  it "computes the roast deficit per product" do
    entry = plan.plan_entries.detect { |row| row.product == coffee_product }
    expect(entry).to be_present
    expect(entry.demand).to eq(4)
    expect(entry.available).to eq(1.5)
    expect(entry.to_roast).to eq(2.5)
    expect(entry.deficit?).to be true
  end

  it "sorts entries by descending roast requirement" do
    # add another entry with no deficit
    other_product = create(:product, name: "Decaf", product_type: :coffee)
    second_order = create(:order, :pending)
    create(:order_item, order: second_order, product: other_product, quantity: 1)
    create(:inventory_item, :roasted, product: other_product, quantity: 2)

    provider = described_class.call
    expect(provider.plan_entries.first.product).to eq(coffee_product)
  end
end
