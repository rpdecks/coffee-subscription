require "rails_helper"

RSpec.describe AffiliateLinksHelper, type: :helper do
  around do |example|
    previous = ENV["AMAZON_ASSOCIATE_TAG"]
    ENV["AMAZON_ASSOCIATE_TAG"] = "acercoffee-20"
    example.run
  ensure
    ENV["AMAZON_ASSOCIATE_TAG"] = previous
  end

  describe "#amazon_url?" do
    it "returns true for Amazon domains" do
      expect(helper.amazon_url?("https://www.amazon.com/dp/B000000000")).to be(true)
      expect(helper.amazon_url?("https://amazon.co.uk/dp/B000000000")).to be(true)
    end

    it "returns true for amzn.to short links" do
      expect(helper.amazon_url?("https://amzn.to/4ruQ5mh")).to be(true)
    end

    it "returns false for non-Amazon URLs" do
      expect(helper.amazon_url?("https://www.sweetmarias.com/roasted-coffee-storage-tin.html")).to be(false)
    end

    it "returns false for blank input" do
      expect(helper.amazon_url?("")).to be(false)
      expect(helper.amazon_url?(nil)).to be(false)
    end
  end

  describe "#amazon_affiliate_url" do
    it "appends the tag to an Amazon URL" do
      url = "https://www.amazon.com/dp/B000000000"
      result = helper.amazon_affiliate_url(url)

      expect(result).to include("amazon.com")
      expect(result).to include("tag=acercoffee-20")
    end

    it "preserves existing query params" do
      url = "https://www.amazon.com/dp/B000000000?th=1&psc=1"
      result = helper.amazon_affiliate_url(url)

      expect(result).to include("th=1")
      expect(result).to include("psc=1")
      expect(result).to include("tag=acercoffee-20")
    end

    it "does not override an existing tag" do
      url = "https://www.amazon.com/dp/B000000000?tag=someoneelse-20"
      result = helper.amazon_affiliate_url(url)

      expect(result).to eq(url)
    end

    it "returns non-Amazon URLs unchanged" do
      url = "https://example.com/products/thing"
      expect(helper.amazon_affiliate_url(url)).to eq(url)
    end

    it "returns nil for blank input" do
      expect(helper.amazon_affiliate_url(""))
        .to be_nil
    end
  end
end
