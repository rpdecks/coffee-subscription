require "rails_helper"

RSpec.describe NewsletterOptInService do
  describe ".subscribe" do
    it "returns false for blank email" do
      allow(ButtondownService).to receive(:configured?).and_return(true)
      expect(ButtondownService).not_to receive(:subscribe)

      expect(described_class.subscribe(email: "")).to eq(false)
    end

    it "returns false for invalid email" do
      allow(ButtondownService).to receive(:configured?).and_return(true)
      expect(ButtondownService).not_to receive(:subscribe)

      expect(described_class.subscribe(email: "not-an-email")).to eq(false)
    end

    it "returns false when Buttondown is not configured" do
      allow(ButtondownService).to receive(:configured?).and_return(false)
      expect(ButtondownService).not_to receive(:subscribe)

      expect(described_class.subscribe(email: "test@example.com")).to eq(false)
    end

    it "calls ButtondownService.subscribe when configured" do
      allow(ButtondownService).to receive(:configured?).and_return(true)
      expect(ButtondownService).to receive(:subscribe).with(email: "test@example.com").and_return(true)

      expect(described_class.subscribe(email: "test@example.com")).to eq(true)
    end

    it "swallows exceptions and returns false" do
      allow(ButtondownService).to receive(:configured?).and_return(true)
      allow(ButtondownService).to receive(:subscribe).and_raise(StandardError, "boom")

      expect(described_class.subscribe(email: "test@example.com")).to eq(false)
    end
  end
end
