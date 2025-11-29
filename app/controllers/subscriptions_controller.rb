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
    else
      # TODO: Create subscription and redirect to Stripe checkout
      flash[:notice] = "Subscription checkout coming soon!"
      redirect_to dashboard_path
    end
  end
end
