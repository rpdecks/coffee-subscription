require "rails_helper"

RSpec.describe SubscriptionOrderGenerator do
  let(:user) { create(:user) }
  let(:subscription_plan) { create(:subscription_plan, bags_per_delivery: 1) }
  let(:shipping_address) { create(:address, user: user) }
  let(:payment_method) { create(:payment_method, user: user) }
  let(:subscription) do
    create(:subscription,
           user: user,
           subscription_plan: subscription_plan,
           status: :active,
           shipping_address: shipping_address,
           payment_method: payment_method,
           next_delivery_date: Date.today)
  end
  let(:product) { create(:product, :coffee, price_cents: 1800) }

  subject(:generator) { described_class.new(subscription) }

  describe "#generate_order" do
    context "with valid subscription" do
      before do
        product # ensure product exists
        allow(OrderMailer).to receive(:order_confirmation).and_return(double(deliver_later: true))
      end

      it "creates an order" do
        expect {
          generator.generate_order
        }.to change(Order, :count).by(1)
      end

      it "sets order attributes correctly" do
        order = generator.generate_order

        expect(order.user).to eq(user)
        expect(order.subscription).to eq(subscription)
        expect(order.order_type).to eq("subscription")
        expect(order.status).to eq("pending")
        expect(order.shipping_address).to eq(shipping_address)
        expect(order.payment_method).to eq(payment_method)
      end

      it "creates order items" do
        order = generator.generate_order

        expect(order.order_items.count).to eq(1)
        expect(order.order_items.first.product).to eq(product)
        expect(order.order_items.first.quantity).to eq(1)
      end

      it "calculates order totals" do
        order = generator.generate_order

        expect(order.subtotal_cents).to eq(1800)
        expect(order.shipping_cents).to eq(500)
        expect(order.tax_cents).to eq(0)
        expect(order.total_cents).to eq(2300)
      end

      it "updates subscription next_delivery_date" do
        initial_date = subscription.next_delivery_date
        generator.generate_order

        expect(subscription.reload.next_delivery_date).to be > initial_date
      end

      it "sends order confirmation email" do
        expect(OrderMailer).to receive(:order_confirmation).and_return(double(deliver_later: true))
        generator.generate_order
      end

      it "logs order creation" do
        allow(Rails.logger).to receive(:info)
        order = generator.generate_order

        expect(Rails.logger).to have_received(:info).with(/Generated order #{order.order_number}/)
      end
    end

    context "when subscription is not active" do
      before do
        subscription.update!(status: :paused)
      end

      it "returns false" do
        expect(generator.generate_order).to be false
      end

      it "does not create an order" do
        expect {
          generator.generate_order
        }.not_to change(Order, :count)
      end

      it "logs a warning" do
        allow(Rails.logger).to receive(:warn)
        generator.generate_order

        expect(Rails.logger).to have_received(:warn).with(/not active/)
      end
    end

    context "when subscription has no shipping address" do
      before do
        subscription.update!(shipping_address: nil)
      end

      it "returns false" do
        expect(generator.generate_order).to be false
      end

      it "does not create an order" do
        expect {
          generator.generate_order
        }.not_to change(Order, :count)
      end

      it "logs a warning" do
        allow(Rails.logger).to receive(:warn)
        generator.generate_order

        expect(Rails.logger).to have_received(:warn).with(/no shipping address/)
      end
    end

    context "when subscription has no payment method" do
      before do
        subscription.update!(payment_method: nil)
      end

      it "returns false" do
        expect(generator.generate_order).to be false
      end

      it "does not create an order" do
        expect {
          generator.generate_order
        }.not_to change(Order, :count)
      end

      it "logs a warning" do
        allow(Rails.logger).to receive(:warn)
        generator.generate_order

        expect(Rails.logger).to have_received(:warn).with(/no payment method/)
      end
    end

    context "when order fails to save" do
      before do
        product
        allow_any_instance_of(Order).to receive(:save).and_return(false)
        allow_any_instance_of(Order).to receive(:errors).and_return(
          double(full_messages: [ "Error message" ])
        )
      end

      it "returns false" do
        expect(generator.generate_order).to be false
      end

      it "logs an error" do
        allow(Rails.logger).to receive(:error)
        generator.generate_order

        expect(Rails.logger).to have_received(:error).with(/Failed to create order/)
      end
    end

    context "with user coffee preferences" do
      let(:coffee_preference) do
        create(:coffee_preference,
               user: user,
               roast_level: :medium_roast,
               grind_type: :coarse)
      end
      let!(:medium_roast) { create(:product, :coffee, roast_type: :medium) }


      before do
        coffee_preference
        allow(OrderMailer).to receive(:order_confirmation).and_return(double(deliver_later: true))
      end

      it "selects products matching preferences" do
        order = generator.generate_order

        expect(order.order_items.first.product).to eq(medium_roast)
      end

      it "uses preferred grind type" do
        order = generator.generate_order

        expect(order.order_items.first.grind_type).to eq("coarse")
      end
    end

    context "with multiple bags per delivery" do
      let(:subscription_plan_multi) { create(:subscription_plan, name: "Multi Pack", bags_per_delivery: 2) }
      let(:subscription_with_multi_plan) do
        create(:subscription,
               user: user,
               subscription_plan: subscription_plan_multi,
               status: :active,
               shipping_address: shipping_address,
               payment_method: payment_method,
               next_delivery_date: Date.today)
      end
      let(:generator_multi) { described_class.new(subscription_with_multi_plan) }

      before do
        # Create 2 products for the subscription to choose from
        create(:product, :coffee, name: "Coffee A", price_cents: 1800)
        create(:product, :coffee, name: "Coffee B", price_cents: 1900)
        allow(OrderMailer).to receive(:order_confirmation).and_return(double(deliver_later: true))
      end

      it "creates order items up to available product count" do
        # Verify we have enough products
        expect(Product.coffee.active.in_stock.count).to eq(2)
        # Verify plan has correct bags_per_delivery
        expect(subscription_plan_multi.bags_per_delivery).to eq(2)

        order = generator_multi.generate_order

        # Should create order items for available products (at least 1, up to bags_per_delivery)
        expect(order.order_items.count).to be >= 1
        expect(order.order_items.count).to be <= 2
      end
    end
  end

  describe "#valid_for_order_generation?" do
    it "returns true for valid subscription" do
      expect(generator.send(:valid_for_order_generation?)).to be true
    end

    it "returns false when not active" do
      subscription.update!(status: :paused)
      expect(generator.send(:valid_for_order_generation?)).to be false
    end

    it "returns false without shipping address" do
      subscription.update!(shipping_address: nil)
      expect(generator.send(:valid_for_order_generation?)).to be false
    end

    it "returns false without payment method" do
      subscription.update!(payment_method: nil)
      expect(generator.send(:valid_for_order_generation?)).to be false
    end
  end

  describe "#calculate_shipping_cost" do
    it "returns flat rate shipping cost" do
      expect(generator.send(:calculate_shipping_cost)).to eq(500)
    end
  end

  describe "#calculate_tax" do
    it "returns zero for now" do
      expect(generator.send(:calculate_tax)).to eq(0)
    end
  end
end
