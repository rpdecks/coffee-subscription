class SubscriptionOrderGenerator
  attr_reader :subscription

  def initialize(subscription)
    @subscription = subscription
  end

  def generate_order
    return false unless valid_for_order_generation?

    order = build_order
    add_order_items(order)
    order.calculate_totals

    if order.save
      update_subscription_delivery_date
      Rails.logger.info("Generated order #{order.order_number} for subscription #{subscription.id}")
      
      # Send order confirmation email
      OrderMailer.order_confirmation(order).deliver_later
      
      order
    else
      Rails.logger.error("Failed to create order for subscription #{subscription.id}: #{order.errors.full_messages}")
      false
    end
  end

  private

  def valid_for_order_generation?
    unless subscription.active?
      Rails.logger.warn("Skipping subscription #{subscription.id} - not active (status: #{subscription.status})")
      return false
    end

    unless subscription.shipping_address
      Rails.logger.warn("Skipping subscription #{subscription.id} - no shipping address")
      return false
    end

    unless subscription.payment_method
      Rails.logger.warn("Skipping subscription #{subscription.id} - no payment method")
      return false
    end

    true
  end

  def build_order
    Order.new(
      user: subscription.user,
      subscription: subscription,
      order_type: :subscription,
      status: :pending,
      shipping_address: subscription.shipping_address,
      payment_method: subscription.payment_method,
      shipping_cents: calculate_shipping_cost,
      tax_cents: calculate_tax
    )
  end

  def add_order_items(order)
    products = select_products_for_subscription
    
    products.each do |product|
      order.order_items.build(
        product: product,
        quantity: 1,
        price_cents: product.price_cents,
        bag_size: subscription.bag_size || '12 oz',
        grind_type: grind_type_for_user
      )
    end
  end

  def select_products_for_subscription
    # Get the number of bags from subscription
    bag_count = subscription.quantity || subscription.subscription_plan.bags_per_delivery || 1
    
    # Get user's coffee preferences if available
    coffee_preference = subscription.user.coffee_preference
    
    # Select active coffee products
    products = Product.coffee.active.in_stock
    
    # If user has preferences, try to match them
    if coffee_preference&.preferred_roast_level
      preferred = products.where(roast_level: coffee_preference.preferred_roast_level).limit(bag_count)
      return preferred if preferred.count == bag_count
    end
    
    # Fall back to any active coffee products
    products.limit(bag_count)
  end

  def grind_type_for_user
    coffee_preference = subscription.user.coffee_preference
    coffee_preference&.preferred_grind_type || :whole_bean
  end

  def calculate_shipping_cost
    # Flat rate shipping for now
    # TODO: Calculate based on weight/distance
    500 # $5.00
  end

  def calculate_tax
    # TODO: Implement tax calculation based on shipping address
    # For now, return 0 - you'll want to integrate with tax service
    0
  end

  def update_subscription_delivery_date
    next_date = subscription.calculate_next_delivery_date
    subscription.update!(next_delivery_date: next_date)
  end
end
