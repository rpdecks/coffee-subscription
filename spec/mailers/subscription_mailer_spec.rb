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
      expect(mail.subject).to eq("Your Acer Coffee subscription is set")
      expect(mail.to).to eq([ "subscriber@example.com" ])
      expect(mail.from.join(",")).to include("hello@acercoffee.com")
    end

    it "renders the body" do
      text = mail.text_part&.body&.decoded
      html = mail.html_part&.body&.decoded

      expect(text).to include(user.first_name)
      expect(text).to include("Monthly Blend")
      expect(text).to include("ships within 3")
      expect(text).to include("Thanks for subscribing. Your Acer Coffee subscription has been created. We’ll email you when your subscription renews and when it ships.")

      expect(html).to include(user.first_name)
      expect(html).to include("Monthly Blend")
      expect(html).to include("ships within 3")
      expect(html).to include("Thanks for subscribing. Your Acer Coffee subscription has been created. We’ll email you when your subscription renews and when it ships.")
    end
  end

  describe "subscription_paused" do
    let(:mail) { SubscriptionMailer.subscription_paused(subscription) }

    it "renders the headers" do
      expect(mail.subject).to eq("Your Acer Coffee subscription is paused")
      expect(mail.to).to eq([ "subscriber@example.com" ])
      expect(mail.from.join(",")).to include("hello@acercoffee.com")
    end

    it "renders the body" do
      text = mail.text_part&.body&.decoded
      html = mail.html_part&.body&.decoded

      bags_per_delivery = subscription.quantity.presence || subscription_plan.bags_per_delivery
      bags_label = bags_per_delivery == 1 ? "1 bag" : "#{bags_per_delivery} bags"

      expect(text).to include(user.first_name)
      expect(text).to include(subscription_plan.frequency.titleize)
      expect(text).to include(bags_label)
      expect(text).to include("subscription is now paused")
      expect(text).to include("no shipments will be created")
      expect(text).to include("Resume your subscription anytime")

      expect(html).to include(user.first_name)
      expect(html).to include(subscription_plan.frequency.titleize)
      expect(html).to include(bags_label)
      expect(html).to include("subscription is now paused")
      expect(html).to include("no shipments will be created")
      expect(html).to include("Resume your subscription anytime")
    end
  end

  describe "subscription_resumed" do
    let(:mail) { SubscriptionMailer.subscription_resumed(subscription) }

    it "renders the headers" do
      expect(mail.subject).to eq("Your Acer Coffee subscription has been resumed")
      expect(mail.to).to eq([ "subscriber@example.com" ])
      expect(mail.from.join(",")).to include("hello@acercoffee.com")
    end

    it "renders the body" do
      text = mail.text_part&.body&.decoded
      html = mail.html_part&.body&.decoded

      bags_per_delivery = subscription.quantity.presence || subscription_plan.bags_per_delivery
      bags_label = bags_per_delivery == 1 ? "1 bag" : "#{bags_per_delivery} bags"

      expect(text).to include(user.first_name)
      expect(text).to include(subscription_plan.frequency.titleize)
      expect(text).to include(bags_label)
      expect(text).to include("subscription has been resumed")
      expect(text).to include("within 3")
      expect(text).to include("business days")
      expect(text).to include("after resuming")
      expect(text).to include("We’ll email you again when it ships")

      expect(html).to include(user.first_name)
      expect(html).to include(subscription_plan.frequency.titleize)
      expect(html).to include(bags_label)
      expect(html).to include("subscription has been resumed")
      expect(html).to include("within 3")
      expect(html).to include("business days")
      expect(html).to include("after resuming")
      expect(html).to include("We’ll email you again when it ships")
    end
  end

  describe "subscription_cancelled" do
    let(:mail) { SubscriptionMailer.subscription_cancelled(subscription) }

    it "renders the headers" do
      expect(mail.subject).to eq("Your subscription has been cancelled")
      expect(mail.to).to eq([ "subscriber@example.com" ])
      expect(mail.from.join(",")).to include("hello@acercoffee.com")
    end

    it "renders the body" do
      text = mail.text_part&.body&.decoded
      html = mail.html_part&.body&.decoded

      bags_per_delivery = subscription.quantity.presence || subscription_plan.bags_per_delivery
      bags_label = bags_per_delivery == 1 ? "1 bag" : "#{bags_per_delivery} bags"

      expect(text).to include(user.first_name)
      expect(text).to include(subscription_plan.frequency.titleize)
      expect(text).to include(bags_label)
      expect(text).to include("subscription has been cancelled")
      expect(text).to include("We’d love your feedback")
      expect(text).to include("please email us and let us know")
      expect(text).to include("Thanks for having been a customer")

      expect(html).to include(user.first_name)
      expect(html).to include(subscription_plan.frequency.titleize)
      expect(html).to include(bags_label)
      expect(html).to include("subscription has been cancelled")
      expect(html).to include("We’d love your feedback")
      expect(html).to include("please email us and let us know")
      expect(html).to include("Thanks for having been a customer")
    end
  end

  describe "payment_failed" do
    let(:mail) { SubscriptionMailer.payment_failed(subscription) }

    before do
      subscription.update(failed_payment_count: 2)
    end

    it "renders the headers" do
      expect(mail.subject).to eq("There was an issue with your Acer Coffee subscription payment")
      expect(mail.to).to eq([ "subscriber@example.com" ])
      expect(mail.from.join(",")).to include("hello@acercoffee.com")
    end

    it "renders the body" do
      text = mail.text_part&.body&.decoded
      html = mail.html_part&.body&.decoded

      bags_per_delivery = subscription.quantity.presence || subscription_plan.bags_per_delivery
      bags_label = bags_per_delivery == 1 ? "1 bag" : "#{bags_per_delivery} bags"

      expect(text).to include(user.first_name)
      expect(text).to include(subscription_plan.frequency.titleize)
      expect(text).to include(bags_label)
      expect(text).to include("problem processing the payment")
      expect(text).to include("take care of the rest")
      expect(text).to include("Update Payment Method")
      expect(text).to include("dashboard/payment_methods")

      expect(html).to include(user.first_name)
      expect(html).to include(subscription_plan.frequency.titleize)
      expect(html).to include(bags_label)
      expect(html).to include("problem processing the payment")
      expect(html).to include("take care of the rest")
      expect(html).to include("Update Payment Method")
      expect(html).to include("dashboard/payment_methods")
    end
  end
end
