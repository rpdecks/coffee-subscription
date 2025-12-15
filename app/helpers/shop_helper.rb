module ShopHelper
  def product_hero_image(product)
    # Map product names to image filenames
    # e.g., "Palmatum Blend" -> "palmatum_05.jpg"
    product_slug = product.name.downcase.gsub(/\s+/, "_").gsub(/[^a-z0-9_]/, "")

    # Try to find a hero image for this product
    hero_image = case product_slug
                 when /palmatum/
                   "products/palmatum_05.jpg"
                 when /deshojo/
                   nil # Image not yet available
                 else
                   nil
                 end

    hero_image
  end
end
