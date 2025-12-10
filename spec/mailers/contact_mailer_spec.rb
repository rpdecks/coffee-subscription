require "rails_helper"

RSpec.describe ContactMailer, type: :mailer do
  describe "contact_form" do
    let(:mail) do
      ContactMailer.contact_form(
        name: "John Doe",
        email: "john@example.com",
        subject: "Test Subject",
        message: "Test message"
      )
    end

    it "renders the headers" do
      expect(mail.subject).to eq("Contact Form: Test Subject")
      expect(mail.to).to eq([ "orders@acercoffee.com" ])
      expect(mail.reply_to).to eq([ "john@example.com" ])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("John Doe")
      expect(mail.body.encoded).to match("Test message")
    end
  end
end
