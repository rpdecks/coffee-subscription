require "rails_helper"

RSpec.describe OrderMailer, type: :mailer do
  let(:user) { create(:user, email: "customer@example.com") }
  let(:product) { create(:product, name: "Ethiopian Blend", price_cents: 1800) }
  let(:order) { create(:order, user: user, order_number: "ORD-12345") }
  let!(:order_item) { create(:order_item, order: order, product: product, quantity: 2) }

  describe "order_confirmation" do
    let(:mail) { OrderMailer.order_confirmation(order) }

    it "renders the headers" do
      expect(mail.subject).to eq("Order Confirmation - ORD-12345")
      expect(mail.to).to eq([ "customer@example.com" ])
      expect(mail.from).to eq([ "orders@acercoffee.com" ])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("ORD-12345")
      expect(mail.body.encoded).to match(user.first_name)
    end

    it "includes order items" do
      expect(mail.body.encoded).to match("Ethiopian Blend")
    end
  end

  describe "order_shipped" do
    let(:mail) { OrderMailer.order_shipped(order) }

    it "renders the headers" do
      expect(mail.subject).to eq("Your order has shipped! - ORD-12345")
      expect(mail.to).to eq([ "customer@example.com" ])
      expect(mail.from).to eq([ "orders@acercoffee.com" ])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("ORD-12345")
      expect(mail.body.encoded).to match(user.first_name)
    end
  end
end
