module ShopHelper
  def product_hero_image(product)
    carousel_images = product.carousel_images
    return carousel_images.first if carousel_images.any?

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
