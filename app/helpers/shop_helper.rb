module ShopHelper
  def shop_product_image_tag(image, alt:, class_name:, loading: "lazy", decoding: "async")
    image_tag(
      optimized_shop_image(image),
      alt: alt,
      loading: loading,
      decoding: decoding,
      class: class_name
    )
  end

  def product_hero_image(product)
    carousel_images = product.carousel_images
    return optimized_shop_image(carousel_images.first) if carousel_images.any?

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

  private

  def optimized_shop_image(image)
    return image unless image.respond_to?(:variable?) && image.variable?

    image.variant(resize_to_limit: [ 640, 640 ])
  end
end
