# frozen_string_literal: true

require "rails_helper"

RSpec.describe RecordRoastService, type: :service do
  let(:product) { create(:product, name: "Palmatum Blend", product_type: :coffee) }
  let!(:green_item) { create(:inventory_item, :green, product: product, quantity: 15.0) }

  let(:valid_params) do
    {
      product: product,
      roasted_weight: 0.94,
      green_weight_used: 1.10,
      roasted_on: Date.today,
      lot_number: "PAL-2026-02-16-A",
      notes: "First batch"
    }
  end

  describe "#call" do
    subject(:result) { described_class.new(**valid_params).call }

    context "with valid params" do
      it "returns a success result" do
        expect(result.success?).to be true
      end

      it "creates a roasted inventory item" do
        expect { result }.to change { InventoryItem.roasted.count }.by(1)

        roasted = result.roasted_item
        expect(roasted.product).to eq(product)
        expect(roasted.state).to eq("roasted")
        expect(roasted.quantity).to eq(0.94)
        expect(roasted.roasted_on).to eq(Date.today)
        expect(roasted.lot_number).to eq("PAL-2026-02-16-A")
      end

      it "debits green inventory" do
        expect { result }.to change { green_item.reload.quantity }.from(15.0).to(13.9)
      end

      it "records green deductions" do
        expect(result.green_deductions.length).to eq(1)

        deduction = result.green_deductions.first
        expect(deduction.amount_debited).to eq(1.10)
        expect(deduction.remaining).to eq(13.9)
      end

      it "calculates weight loss percentage" do
        expect(result.weight_loss_pct).to eq(14.5)
      end

      it "includes weight loss info in notes" do
        expect(result.roasted_item.notes).to include("Green used: 1.1 lbs")
        expect(result.roasted_item.notes).to include("14.5% loss")
        expect(result.roasted_item.notes).to include("First batch")
      end
    end

    context "FIFO green deduction across multiple lots" do
      let!(:green_item) { create(:inventory_item, :green, product: product, quantity: 0.5, received_on: 2.weeks.ago) }
      let!(:green_item_2) { create(:inventory_item, :green, product: product, quantity: 10.0, received_on: 1.week.ago) }

      it "debits oldest green lot first" do
        result
        expect(green_item.reload.quantity).to eq(0.0)
        expect(green_item_2.reload.quantity).to eq(9.4)
      end

      it "records multiple deductions" do
        expect(result.green_deductions.length).to eq(2)
        expect(result.green_deductions.first.amount_debited).to eq(0.5)
        expect(result.green_deductions.last.amount_debited).to eq(0.6)
      end
    end

    context "when green inventory is insufficient" do
      let!(:green_item) { create(:inventory_item, :green, product: product, quantity: 0.5) }

      it "still succeeds (with warning)" do
        expect(result.success?).to be true
      end

      it "debits whatever is available" do
        expect { result }.to change { green_item.reload.quantity }.from(0.5).to(0.0)
      end

      it "includes a warning about shortfall" do
        expect(result.errors).to include(match(/could not be debited/))
      end
    end

    context "when no green inventory exists" do
      before { InventoryItem.green.destroy_all }

      it "still succeeds (with warning)" do
        expect(result.success?).to be true
      end

      it "creates the roasted item anyway" do
        expect { result }.to change { InventoryItem.roasted.count }.by(1)
      end

      it "warns about the full shortfall" do
        expect(result.errors).to include(match(/1.1 lbs of green coffee could not be debited/))
      end
    end

    context "with no product" do
      let(:valid_params) { super().merge(product: nil) }

      it "returns failure" do
        expect(result.success?).to be false
        expect(result.errors).to include("Product is required")
      end

      it "does not create any inventory items" do
        expect { result }.not_to change { InventoryItem.count }
      end
    end

    context "with zero roasted weight" do
      let(:valid_params) { super().merge(roasted_weight: 0) }

      it "returns failure" do
        expect(result.success?).to be false
        expect(result.errors).to include("Roasted weight must be greater than zero")
      end
    end

    context "when green weight <= roasted weight" do
      let(:valid_params) { super().merge(green_weight_used: 0.90, roasted_weight: 0.94) }

      it "returns failure" do
        expect(result.success?).to be false
        expect(result.errors).to include(match(/weight loss/))
      end

      it "does not create any inventory items" do
        expect { result }.not_to change { InventoryItem.count }
      end

      it "does not debit green inventory" do
        expect { result }.not_to change { green_item.reload.quantity }
      end
    end

    context "with missing roast date" do
      let(:valid_params) { super().merge(roasted_on: nil) }

      it "returns failure" do
        expect(result.success?).to be false
        expect(result.errors).to include("Roast date is required")
      end
    end

    context "transaction rollback" do
      it "rolls back roasted item if green debit fails" do
        allow_any_instance_of(InventoryItem).to receive(:update!).and_raise(ActiveRecord::RecordInvalid.new(green_item))
        result = described_class.new(**valid_params).call
        expect(result.success?).to be false
        expect(InventoryItem.roasted.count).to eq(0)
      end
    end
  end
end
