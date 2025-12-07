require 'rails_helper'

RSpec.describe Product, type: :model do
  describe 'validations' do
    it 'validates presence of name' do
      product = build(:product, name: nil)
      expect(product).not_to be_valid
      expect(product.errors[:name]).to include("can't be blank")
    end

    it 'validates presence of price_cents' do
      product = build(:product, price_cents: nil)
      expect(product).not_to be_valid
      expect(product.errors[:price_cents]).to include("can't be blank")
    end

    it 'validates price_cents is greater than 0' do
      product = build(:product, price_cents: 0)
      expect(product).not_to be_valid
      expect(product.errors[:price_cents]).to include("must be greater than 0")
    end
  end

  describe 'scopes' do
    let!(:active_coffee) { create(:product, active: true, product_type: :coffee, visible_in_shop: true, inventory_count: 10) }
    let!(:active_merch) { create(:product, active: true, product_type: :merch, visible_in_shop: true, inventory_count: 5) }
    let!(:hidden_product) { create(:product, active: true, visible_in_shop: false, inventory_count: 10) }
    let!(:inactive_product) { create(:product, active: false, visible_in_shop: true) }
    let!(:out_of_stock) { create(:product, active: true, visible_in_shop: true, inventory_count: 0) }

    describe '.active' do
      it 'returns only active products' do
        expect(Product.active).to include(active_coffee, active_merch, hidden_product)
        expect(Product.active).not_to include(inactive_product)
      end
    end

    describe '.visible_in_shop' do
      it 'returns only visible products' do
        expect(Product.visible_in_shop).to include(active_coffee, active_merch, inactive_product)
        expect(Product.visible_in_shop).not_to include(hidden_product)
      end
    end

    describe '.coffee' do
      it 'returns only coffee products' do
        expect(Product.coffee).to include(active_coffee)
        expect(Product.coffee).not_to include(active_merch)
      end
    end

    describe '.merch' do
      it 'returns only merchandise products' do
        expect(Product.merch).to include(active_merch)
        expect(Product.merch).not_to include(active_coffee)
      end
    end

    describe '.in_stock' do
      it 'returns products with inventory or unlimited stock' do
        expect(Product.in_stock).to include(active_coffee, active_merch)
        expect(Product.in_stock).not_to include(out_of_stock)
      end
    end
  end

  describe '#price' do
    it 'converts price_cents to dollars' do
      product = create(:product, price_cents: 1850)
      expect(product.price).to eq(18.50)
    end
  end

  describe '#price=' do
    it 'converts dollars to price_cents' do
      product = build(:product)
      product.price = 19.99
      expect(product.price_cents).to eq(1999)
    end
  end

  describe '#in_stock?' do
    it 'returns true for unlimited inventory' do
      product = create(:product, inventory_count: nil)
      expect(product.in_stock?).to be true
    end

    it 'returns true for positive inventory' do
      product = create(:product, inventory_count: 5)
      expect(product.in_stock?).to be true
    end

    it 'returns false for zero inventory' do
      product = create(:product, inventory_count: 0)
      expect(product.in_stock?).to be false
    end
  end
end
