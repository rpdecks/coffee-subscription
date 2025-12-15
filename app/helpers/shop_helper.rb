module ShopHelper
  def product_hero_image(product)
    # Map product names to image filenames
    # e.g., "Palmatum Blend" -> "palmatum_05.jpg"
    product_slug = product.name.downcase.gsub(/\s+/, "_").gsub(/[^a-z0-9_]/, "")

    # Try to find a hero image for this product
    hero_image = case product_slug
    when /palmatum/
                   "products/palmatum_05.jpg" # Most polished palmatum image
    when /deshojo/
                   "products/deshojo_hero.jpg" # Will add when available
    else
                   nil
    end

    hero_image
  end
end
