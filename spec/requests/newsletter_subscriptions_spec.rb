require "rails_helper"

RSpec.describe "Newsletter subscriptions", type: :request do
  describe "GET /newsletter/thanks" do
    it "returns http success" do
      get newsletter_thanks_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /newsletter/subscribe" do
    it "rejects invalid email" do
      post newsletter_subscribe_path, params: { email: "not-an-email" }

      expect(response).to redirect_to(root_path(anchor: "newsletter"))
      follow_redirect!
      expect(flash[:alert]).to match(/valid email/i)
    end

    it "rejects when Buttondown is not configured" do
      allow(ButtondownService).to receive(:configured?).and_return(false)

      post newsletter_subscribe_path, params: { email: "test@example.com" }

      expect(response).to redirect_to(root_path(anchor: "newsletter"))
      follow_redirect!
      expect(flash[:alert]).to match(/temporarily unavailable/i)
    end

    it "redirects to thanks on success" do
      allow(ButtondownService).to receive(:configured?).and_return(true)
      allow(ButtondownService).to receive(:subscribe).with(email: "test@example.com").and_return(true)

      post newsletter_subscribe_path, params: { email: "test@example.com" }

      expect(response).to redirect_to(newsletter_thanks_path)
      follow_redirect!
      expect(flash[:notice]).to match(/check your inbox/i)
    end

    it "redirects to thanks on failure" do
      allow(ButtondownService).to receive(:configured?).and_return(true)
      allow(ButtondownService).to receive(:subscribe).with(email: "test@example.com").and_return(false)

      post newsletter_subscribe_path, params: { email: "test@example.com" }

      expect(response).to redirect_to(newsletter_thanks_path)
      follow_redirect!
      expect(flash[:alert]).to match(/couldn't subscribe/i)
    end
  end
end
