require "rails_helper"

RSpec.describe SubscriptionMailer, type: :mailer do
  let(:user) { create(:user, email: "subscriber@example.com") }
  let(:subscription_plan) { create(:subscription_plan, name: "Monthly Blend", price_cents: 2500) }
  let(:subscription) do
    create(:subscription,
           user: user,
           subscription_plan: subscription_plan,
           status: :active,
           next_delivery_date: 7.days.from_now)
  end

  describe "subscription_created" do
    let(:mail) { SubscriptionMailer.subscription_created(subscription) }

    it "renders the headers" do
      expect(mail.subject).to eq("Welcome to your coffee subscription!")
      expect(mail.to).to eq(["subscriber@example.com"])
      expect(mail.from).to eq(["orders@acercoffee.com"])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match(user.first_name)
      expect(mail.body.encoded).to match("Monthly Blend")
    end
  end

  describe "subscription_paused" do
    let(:mail) { SubscriptionMailer.subscription_paused(subscription) }

    it "renders the headers" do
      expect(mail.subject).to eq("Your subscription has been paused")
      expect(mail.to).to eq(["subscriber@example.com"])
      expect(mail.from).to eq(["orders@acercoffee.com"])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match(user.first_name)
      expect(mail.body.encoded).to match("Monthly Blend")
    end
  end

  describe "subscription_resumed" do
    let(:mail) { SubscriptionMailer.subscription_resumed(subscription) }

    it "renders the headers" do
      expect(mail.subject).to eq("Your subscription has been resumed")
      expect(mail.to).to eq(["subscriber@example.com"])
      expect(mail.from).to eq(["orders@acercoffee.com"])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match(user.first_name)
      expect(mail.body.encoded).to match("Monthly Blend")
    end
  end

  describe "subscription_cancelled" do
    let(:mail) { SubscriptionMailer.subscription_cancelled(subscription) }

    it "renders the headers" do
      expect(mail.subject).to eq("Your subscription has been cancelled")
      expect(mail.to).to eq(["subscriber@example.com"])
      expect(mail.from).to eq(["orders@acercoffee.com"])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match(user.first_name)
      expect(mail.body.encoded).to match("Monthly Blend")
    end
  end

  describe "payment_failed" do
    let(:mail) { SubscriptionMailer.payment_failed(subscription) }

    before do
      subscription.update(failed_payment_count: 2)
    end

    it "renders the headers" do
      expect(mail.subject).to eq("Payment failed for your coffee subscription")
      expect(mail.to).to eq(["subscriber@example.com"])
      expect(mail.from).to eq(["orders@acercoffee.com"])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match(user.first_name)
      expect(mail.body.encoded).to match("Monthly Blend")
    end

    it "includes the failed payment count" do
      expect(mail.body.encoded).to match("twice")
    end

    it "includes the update payment URL" do
      expect(mail.body.encoded).to match("dashboard/payment_methods")
    end
  end
end
