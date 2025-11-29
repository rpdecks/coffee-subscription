class Dashboard::PaymentMethodsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_payment_method, only: [:destroy]

  def index
    @payment_methods = current_user.payment_methods.order(is_default: :desc, created_at: :desc)
  end

  def new
    @payment_method = current_user.payment_methods.new
  end

  def create
    # Stripe payment method ID comes from the frontend
    stripe_pm_id = params[:stripe_payment_method_id]
    
    begin
      # Retrieve payment method details from Stripe
      stripe_pm = Stripe::PaymentMethod.retrieve(stripe_pm_id)
      
      # Attach to customer if not already
      unless stripe_pm.customer
        customer_id = current_user.stripe_customer_id || create_stripe_customer
        # Just attach the payment method - don't validate funds at this point
        # Funds will be checked when actually processing a payment
        stripe_pm.attach(customer: customer_id)
      end
      
      # Create local payment method record
      @payment_method = current_user.payment_methods.create!(
        stripe_payment_method_id: stripe_pm.id,
        card_brand: stripe_pm.card.brand.capitalize,
        last_four: stripe_pm.card.last4,
        exp_month: stripe_pm.card.exp_month,
        exp_year: stripe_pm.card.exp_year,
        is_default: params[:is_default] == "1" || current_user.payment_methods.none?
      )
      
      redirect_to dashboard_payment_methods_path, notice: "Payment method added successfully."
    rescue Stripe::CardError => e
      # Card errors (like insufficient funds during attach) shouldn't block saving the card
      # The card is still valid, just may not have funds right now
      redirect_to new_dashboard_payment_method_path, alert: "Unable to add this card. Please try a different card."
    rescue Stripe::StripeError => e
      redirect_to new_dashboard_payment_method_path, alert: "Error adding payment method: #{e.message}"
    end
  end

  def destroy
    begin
      # Detach from Stripe
      Stripe::PaymentMethod.detach(@payment_method.stripe_payment_method_id)
      
      # Delete local record
      @payment_method.destroy
      
      redirect_to dashboard_payment_methods_path, notice: "Payment method removed successfully."
    rescue Stripe::StripeError => e
      redirect_to dashboard_payment_methods_path, alert: "Error removing payment method: #{e.message}"
    end
  end

  private

  def set_payment_method
    @payment_method = current_user.payment_methods.find(params[:id])
  end

  def create_stripe_customer
    customer = Stripe::Customer.create(
      email: current_user.email,
      name: current_user.email.split("@").first
    )
    current_user.update!(stripe_customer_id: customer.id)
    customer.id
  end
end
