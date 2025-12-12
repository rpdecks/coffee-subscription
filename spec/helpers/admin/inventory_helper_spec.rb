require 'rails_helper'
require 'capybara'
require 'capybara'

RSpec.describe Admin::InventoryHelper, type: :helper do
  def parsed_html(result)
    Capybara::Node::Simple.new(result)
  end

  describe "#inventory_state_badge" do
    it "returns green badge for green state" do
      result = parsed_html(helper.inventory_state_badge("green"))
      expect(result).to have_css("span.bg-green-100.text-green-800", text: "Green")
    end

    it "returns amber badge for roasted state" do
      result = parsed_html(helper.inventory_state_badge("roasted"))
      expect(result).to have_css("span.bg-amber-100.text-amber-800", text: "Roasted")
    end

    it "returns blue badge for packaged state" do
      result = parsed_html(helper.inventory_state_badge("packaged"))
      expect(result).to have_css("span.bg-blue-100.text-blue-800", text: "Packaged")
    end

    it "includes proper styling classes" do
      result = parsed_html(helper.inventory_state_badge("green"))
      expect(result).to have_css("span.px-2.py-1.inline-flex.text-xs.font-semibold.rounded-full")
    end
  end

  describe "#inventory_freshness_badge" do
    let(:product) { create(:product, product_type: :coffee) }

    context "when item has no roast date" do
      let(:item) { create(:inventory_item, product: product, roasted_on: nil) }

      it "returns placeholder" do
        result = parsed_html(helper.inventory_freshness_badge(item))
        expect(result).to have_css("span.text-sm.text-gray-500", text: "—")
      end
    end

    context "when product is not coffee" do
      let(:merch_product) { create(:product, product_type: :merch) }
      let(:item) { create(:inventory_item, product: merch_product, roasted_on: 5.days.ago.to_date) }

      it "returns placeholder" do
        result = parsed_html(helper.inventory_freshness_badge(item))
        expect(result).to have_css("span.text-sm.text-gray-500", text: "—")
      end
    end

    context "when coffee roasted within 7 days" do
      let(:item) { create(:inventory_item, product: product, roasted_on: 5.days.ago.to_date) }

      it "returns fresh badge" do
        result = parsed_html(helper.inventory_freshness_badge(item))
        expect(result).to have_css("span.bg-green-100.text-green-800", text: /Fresh \(#{item.days_since_roast}d\)/)
      end
    end

    context "when coffee roasted 8-21 days ago" do
      let(:item) { create(:inventory_item, product: product, roasted_on: 15.days.ago.to_date) }

      it "returns good badge" do
        result = parsed_html(helper.inventory_freshness_badge(item))
        expect(result).to have_css("span.bg-yellow-100.text-yellow-800", text: /Good \(#{item.days_since_roast}d\)/)
      end
    end

    context "when coffee roasted more than 21 days ago" do
      let(:item) { create(:inventory_item, product: product, roasted_on: 30.days.ago.to_date) }

      it "returns aging badge" do
        result = parsed_html(helper.inventory_freshness_badge(item))
        expect(result).to have_css("span.bg-gray-100.text-gray-800", text: /Aging \(#{item.days_since_roast}d\)/)
      end
    end
  end

  describe "#inventory_quantity_status" do
    context "when quantity is zero" do
      it "returns out of stock message" do
        result = parsed_html(helper.inventory_quantity_status(0))
        expect(result).to have_css("div.text-xs.text-red-600", text: "Out of Stock")
      end
    end

    context "when quantity is low (1-5)" do
      it "returns low stock message" do
        result = parsed_html(helper.inventory_quantity_status(3))
        expect(result).to have_css("div.text-xs.text-yellow-600", text: "Low Stock")
      end
    end

    context "when quantity is adequate" do
      it "returns nil" do
        result = helper.inventory_quantity_status(10)
        expect(result).to be_nil
      end
    end
  end
end
