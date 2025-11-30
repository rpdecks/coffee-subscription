namespace :db do
  desc "Update existing products with better details"
  task update_products: :environment do
    products_data = [
      {
        name: "Ethiopian Yirgacheffe",
        description: "A bright and floral coffee with notes of blueberry, lemon, and jasmine. This naturally processed coffee from the Yirgacheffe region offers a clean, tea-like body with complex fruit flavors.",
        price_cents: 1599,
        weight_oz: 12.0,
        active: true
      },
      {
        name: "Colombian Supremo",
        description: "A well-balanced medium roast with chocolate and caramel notes. Grown in the high altitudes of Colombia, this coffee delivers a smooth, full-bodied cup with a sweet finish.",
        price_cents: 1499,
        weight_oz: 12.0,
        active: true
      },
      {
        name: "Sumatra Mandheling",
        description: "A bold, full-bodied dark roast with earthy, herbal notes and a syrupy consistency. This Indonesian coffee is known for its low acidity and complex, lingering finish.",
        price_cents: 1699,
        weight_oz: 12.0,
        active: true
      }
    ]

    products_data.each do |data|
      product = Product.find_by(name: data[:name])
      if product
        product.update!(data)
        puts "Updated #{product.name}"
      else
        Product.create!(data.merge(product_type: :coffee))
        puts "Created #{data[:name]}"
      end
    end

    puts "\n✅ Products updated successfully!"
  end
end
