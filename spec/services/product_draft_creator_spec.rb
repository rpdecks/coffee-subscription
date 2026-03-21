# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProductDraftCreator do
  describe ".call" do
    it "creates a coffee product from draft attributes" do
      result = described_class.call(params: {
        name: "Salmo Plus Natural",
        description: "Origin: Cerrado, Minas Gerais, Brazil",
        product_type: "coffee",
        roast_type: "medium",
        price: 15,
        weight_oz: 12,
        active: true,
        visible_in_shop: true
      })

      expect(result).to be_success
      expect(result.errors).to be_empty
      expect(result.product).to be_persisted
      expect(result.product.name).to eq("Salmo Plus Natural")
      expect(result.product.roast_type).to eq("medium")
      expect(result.product.price_cents).to eq(1500)
      expect(result.product.weight_oz.to_f).to eq(12.0)
      expect(result.product.visible_in_shop).to be(true)
    end

    it "returns validation errors for an incomplete draft" do
      result = described_class.call(params: {
        name: "Missing Price Coffee",
        product_type: "coffee"
      })

      expect(result).not_to be_success
      expect(result.product).not_to be_persisted
      expect(result.errors).to include("Price cents can't be blank")
    end
  end
end
