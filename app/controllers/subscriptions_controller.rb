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

  # Step 4: Proceed to checkout with Stripe
  def checkout
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

    # Store subscription preferences in session for webhook to use
    session[:pending_subscription] = {
      plan_id: plan.id,
      bag_size: params[:bag_size] || '12oz',
      frequency: params[:frequency] || plan.frequency,
      grind_type: params[:grind_type],
      coffee_id: params[:coffee_id]
    }

    # Create Stripe checkout session
    begin
      checkout_session = StripeService.create_checkout_session(
        user: current_user,
        plan: plan,
        success_url: subscription_success_url,
        cancel_url: subscription_plans_url,
        metadata: {
          bag_size: params[:bag_size] || '12oz',
          frequency: params[:frequency] || plan.frequency,
          grind_type: params[:grind_type],
          coffee_id: params[:coffee_id]
        }
      )

      redirect_to checkout_session.url, allow_other_host: true
    rescue StripeService::StripeError => e
      Rails.logger.error("Stripe checkout failed: #{e.message}")
      flash[:alert] = "Unable to create checkout session. Please try again or contact support."
      redirect_to customize_subscription_path(plan_id: plan.id)
    end
  end

  # Success callback after Stripe checkout
  def success
    session_id = params[:session_id]
    
    if session_id.blank?
      flash[:alert] = "Invalid checkout session"
      redirect_to subscription_plans_path
      return
    end

    # Retrieve the checkout session from Stripe
    begin
      checkout_session = Stripe::Checkout::Session.retrieve(session_id)
      
      # Find or create the subscription based on Stripe subscription ID
      subscription = current_user.subscriptions.find_by(
        stripe_subscription_id: checkout_session.subscription
      )

      if subscription
        flash[:success] = "Welcome to your coffee subscription! Your first delivery will arrive soon."
        redirect_to dashboard_subscription_path(subscription)
      else
        flash[:notice] = "Your subscription is being processed. Check your dashboard shortly."
        redirect_to dashboard_root_path
      end
    rescue Stripe::StripeError => e
      Rails.logger.error("Error retrieving checkout session: #{e.message}")
      flash[:alert] = "There was an issue confirming your subscription. Please contact support if you were charged."
      redirect_to dashboard_root_path
    end
  end
end
