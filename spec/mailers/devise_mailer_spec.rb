require "rails_helper"

RSpec.describe DeviseMailer, type: :mailer do
  let(:user) { create(:user, email: "customer@example.com") }
  let(:token) { "test-reset-token" }

  describe "reset_password_instructions" do
    let(:mail) { Devise.mailer.reset_password_instructions(user, token) }

    it "includes a reset token" do
      expect(mail.body.encoded).to include("reset_password_token")
    end

    it "disables SendGrid click tracking" do
      header = mail.header["X-SMTPAPI"]
      expect(header).to be_present

      payload = JSON.parse(header.value)
      expect(payload.dig("filters", "clicktrack", "settings", "enable")).to eq(0)
    end
  end

  describe "confirmation_instructions" do
    let(:mail) { Devise.mailer.confirmation_instructions(user, "test-confirm-token") }

    it "disables SendGrid click tracking" do
      payload = JSON.parse(mail.header["X-SMTPAPI"].value)
      expect(payload.dig("filters", "clicktrack", "settings", "enable")).to eq(0)
    end
  end
end
