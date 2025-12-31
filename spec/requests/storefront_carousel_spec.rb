require "rails_helper"
require "capybara"

RSpec.describe "Storefront carousel", type: :request do
  def attach_test_image(product, filename)
    product.images.attach(
      io: StringIO.new("test"),
      filename: filename,
      content_type: "image/png"
    )
  end

  def card_for_products_index(doc, product)
    doc.find(:xpath, "//h3[contains(normalize-space(.), '#{product.name}')]/ancestor::div[contains(@class,'group')][1]")
  end

  def card_for_shop_index(doc, product)
    doc.find(:xpath, "//h3[contains(normalize-space(.), '#{product.name}')]/ancestor::div[contains(@class,'card')][1]")
  end

  it "renders carousel controls on /products when a product has multiple images" do
    product_with_images = create(:product, name: "Carousel Products With Images")
    product_without_images = create(:product, name: "Carousel Products Without Images")

    attach_test_image(product_with_images, "a.png")
    attach_test_image(product_with_images, "b.png")

    get products_path
    expect(response).to have_http_status(:success)

    doc = Capybara.string(response.body)

    with_images_card = card_for_products_index(doc, product_with_images)
    expect(with_images_card.has_css?("[data-controller='product-carousel'][data-product-carousel-count-value='2']")).to eq(true)
    expect(with_images_card.has_css?("[data-action='product-carousel#prev']")).to eq(true)
    expect(with_images_card.has_css?("[data-action='product-carousel#next']")).to eq(true)

    without_images_card = card_for_products_index(doc, product_without_images)
    expect(without_images_card.has_css?("[data-controller='product-carousel']")).to eq(false)
  end

  it "renders carousel controls on /shop when a product has multiple images" do
    product_with_images = create(:product, name: "Carousel Shop With Images")
    product_without_images = create(:product, name: "Carousel Shop Without Images")

    attach_test_image(product_with_images, "a.png")
    attach_test_image(product_with_images, "b.png")

    get shop_path
    expect(response).to have_http_status(:success)

    doc = Capybara.string(response.body)

    with_images_card = card_for_shop_index(doc, product_with_images)
    expect(with_images_card.has_css?("[data-controller='product-carousel'][data-product-carousel-count-value='2']")).to eq(true)
    expect(with_images_card.has_css?("[data-action='product-carousel#prev']")).to eq(true)
    expect(with_images_card.has_css?("[data-action='product-carousel#next']")).to eq(true)

    without_images_card = card_for_shop_index(doc, product_without_images)
    expect(without_images_card.has_css?("[data-controller='product-carousel']")).to eq(false)
  end

  it "renders carousel controls on product show pages when a product has multiple images" do
    product_with_images = create(:product, name: "Carousel Show With Images")
    product_without_images = create(:product, name: "Carousel Show Without Images")

    attach_test_image(product_with_images, "a.png")
    attach_test_image(product_with_images, "b.png")

    get product_path(product_with_images)
    expect(response).to have_http_status(:success)

    doc = Capybara.string(response.body)
    expect(doc.has_css?("[data-controller='product-carousel'][data-product-carousel-count-value='2']")).to eq(true)
    expect(doc.has_css?("[data-action='product-carousel#prev']")).to eq(true)
    expect(doc.has_css?("[data-action='product-carousel#next']")).to eq(true)

    get product_path(product_without_images)
    expect(response).to have_http_status(:success)

    doc = Capybara.string(response.body)
    expect(doc.has_css?("[data-controller='product-carousel']")).to eq(false)
  end

  it "renders carousel controls on shop product show pages when a product has multiple images" do
    product_with_images = create(:product, name: "Carousel Shop Show With Images")
    product_without_images = create(:product, name: "Carousel Shop Show Without Images")

    attach_test_image(product_with_images, "a.png")
    attach_test_image(product_with_images, "b.png")

    get shop_product_path(product_with_images)
    expect(response).to have_http_status(:success)

    doc = Capybara.string(response.body)
    expect(doc.has_css?("[data-controller='product-carousel'][data-product-carousel-count-value='2']")).to eq(true)
    expect(doc.has_css?("[data-action='product-carousel#prev']")).to eq(true)
    expect(doc.has_css?("[data-action='product-carousel#next']")).to eq(true)

    get shop_product_path(product_without_images)
    expect(response).to have_http_status(:success)

    doc = Capybara.string(response.body)
    expect(doc.has_css?("[data-controller='product-carousel']")).to eq(false)
  end
end
