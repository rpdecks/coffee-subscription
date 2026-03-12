require "rails_helper"

RSpec.describe ShopHelper, type: :helper do
  describe "#shop_product_image_tag" do
    let(:fixture_path) { Rails.root.join("spec/fixtures/files/test_avatar.jpg") }
    let(:blob) do
      ActiveStorage::Blob.create_and_upload!(
        io: File.open(fixture_path),
        filename: "test_avatar.jpg",
        content_type: "image/jpeg"
      )
    end

    it "renders an Active Storage representation with async image attributes" do
      html = helper.shop_product_image_tag(
        blob,
        alt: "Test image",
        class_name: "w-full h-full object-contain p-4"
      )

      expect(html).to include("/rails/active_storage/representations/")
      expect(html).to include('loading="lazy"')
      expect(html).to include('decoding="async"')
      expect(html).to include('alt="Test image"')
    end
  end
end
