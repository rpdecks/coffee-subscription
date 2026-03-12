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

    describe '.admin_in_stock' do
      it 'uses packaged coffee inventory for coffee products' do
        in_stock_coffee = create(:product, :coffee, inventory_count: 40, weight_oz: 12)
        out_of_stock_coffee = create(:product, :coffee, inventory_count: 40, weight_oz: 12)
        merch = create(:product, :merch, inventory_count: 3)

        create(:inventory_item, :packaged, product: in_stock_coffee, quantity: 1.0)

        expect(Product.admin_in_stock).to include(in_stock_coffee, merch)
        expect(Product.admin_in_stock).not_to include(out_of_stock_coffee)
      end
    end

    describe '.admin_out_of_stock' do
      it 'uses packaged coffee inventory for coffee products' do
        in_stock_coffee = create(:product, :coffee, inventory_count: 0, weight_oz: 12)
        out_of_stock_coffee = create(:product, :coffee, inventory_count: 40, weight_oz: 12)
        merch = create(:product, :merch, inventory_count: 0)

        create(:inventory_item, :packaged, product: in_stock_coffee, quantity: 1.0)

        expect(Product.admin_out_of_stock).to include(out_of_stock_coffee, merch)
        expect(Product.admin_out_of_stock).not_to include(in_stock_coffee)
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
    context 'for coffee products' do
      it 'returns true when packaged inventory yields at least 1 bag' do
        product = create(:product, :coffee, weight_oz: 12, inventory_count: 0)
        create(:inventory_item, :packaged, product: product, quantity: 3.0) # 48 oz => 4 bags

        expect(product.sellable_bag_count).to eq(4)
        expect(product.in_stock?).to be true
      end

      it 'returns false when there is no packaged inventory' do
        product = create(:product, :coffee, weight_oz: 12, inventory_count: 100)
        expect(product.sellable_bag_count).to eq(0)
        expect(product.in_stock?).to be false
      end

      it 'returns nil for sellable_bag_count when bag sizing is not configured' do
        product = create(:product, :coffee, weight_oz: nil, inventory_count: 5)
        expect(product.sellable_bag_count).to be_nil
        expect(product.in_stock?).to be true
      end
    end

    context 'for merch products' do
      it 'returns true for unlimited inventory' do
        product = create(:product, :merch, inventory_count: nil)
        expect(product.in_stock?).to be true
      end

      it 'returns true for positive inventory' do
        product = create(:product, :merch, inventory_count: 5)
        expect(product.in_stock?).to be true
      end

      it 'returns false for zero inventory' do
        product = create(:product, :merch, inventory_count: 0)
        expect(product.in_stock?).to be false
      end
    end
  end

  describe '#admin_inventory_display' do
    it 'shows bag counts for coffee products' do
      product = create(:product, :coffee, weight_oz: 12, inventory_count: 40)
      create(:inventory_item, :packaged, product: product, quantity: 1.94)

      expect(product.admin_inventory_display).to eq('2 bags')
      expect(product.admin_inventory_display_class).to eq('text-sm text-yellow-600 font-medium')
    end

    it 'shows not configured for coffee products without bag sizing' do
      product = create(:product, :coffee, weight_oz: nil, inventory_count: 40)

      expect(product.admin_inventory_display).to eq('Not configured')
      expect(product.admin_inventory_display_class).to eq('text-sm text-gray-500')
    end

    it 'shows inventory_count for merch products' do
      product = create(:product, :merch, inventory_count: 30)

      expect(product.admin_inventory_display).to eq('30')
      expect(product.admin_inventory_display_class).to eq('text-sm text-green-600 font-medium')
    end
  end
end
