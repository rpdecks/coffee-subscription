module ShopHelper
  def product_hero_image(product)
    # First check if product has an attached image
    if product.image.attached?
      return product.image
    end

    # Fallback to static image mappings for legacy support
    product_slug = product.name.downcase.gsub(/\s+/, "_").gsub(/[^a-z0-9_]/, "")
    case product_slug
    when /palmatum/
      "products/palmatum.jpeg"
    when /deshojo/
      "products/palmatum_03.jpg"
    else
      nil
    end
  end
end
