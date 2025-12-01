class SubscriptionsController < ApplicationController
  # Step 1: Landing page explaining subscriptions
  def landing
  end

  # Step 2: Show available subscription plans
  def plans
    @subscription_plans = SubscriptionPlan.active.order(:price_cents)
  end

  # Step 3: Customize selected plan
  def customize
    @plan = SubscriptionPlan.find(params[:plan_id])
    @coffee_products = Product.coffee.active
  rescue ActiveRecord::RecordNotFound
    flash[:alert] = "Subscription plan not found"
    redirect_to subscription_plans_path
  end

  # Step 4: Proceed to checkout
  def checkout
    # This will eventually integrate with Stripe
    # For now, redirect to sign up if not authenticated
    unless user_signed_in?
      session[:subscription_params] = params.permit(:plan_id, :bag_size, :frequency, :grind_type, :coffee_id)
      flash[:notice] = "Please sign in or create an account to complete your subscription"
      redirect_to new_user_registration_path
      return
    end

    # Check if user already has an active subscription
    if current_user.subscriptions.active.exists?
      flash[:alert] = "You already have an active subscription. Please manage it from your dashboard."
      redirect_to dashboard_root_path
      return
    end

    # Validate required parameters
    plan = SubscriptionPlan.find_by(id: params[:plan_id])
    unless plan
      flash[:alert] = "Invalid subscription plan selected"
      redirect_to subscription_plans_path
      return
    end

    # Ensure user has address and payment method
    unless current_user.addresses.any?
      flash[:alert] = "Please add a shipping address before creating a subscription"
      redirect_to new_dashboard_address_path
      return
    end

    unless current_user.payment_methods.any?
      flash[:alert] = "Please add a payment method before creating a subscription"
      redirect_to new_dashboard_payment_method_path
      return
    end

    # Create the subscription
    subscription = current_user.subscriptions.build(
      subscription_plan: plan,
      bag_size: params[:bag_size] || '12oz',
      quantity: 1, # Default to 1 bag
      status: :active,
      next_delivery_date: Date.today + plan.frequency.to_i.days,
      shipping_address_id: current_user.addresses.first.id,
      payment_method_id: current_user.payment_methods.first.id
    )

    if subscription.save
      flash[:notice] = "Subscription created successfully! Welcome to your coffee subscription."
      redirect_to dashboard_subscription_path(subscription)
    else
      flash[:alert] = "Unable to create subscription: #{subscription.errors.full_messages.join(', ')}"
      redirect_to customize_subscription_path(plan_id: plan.id)
    end
  end
end
