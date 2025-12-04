class Dashboard::PaymentMethodsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_payment_method, only: [:destroy, :set_default]

  def index
    @payment_methods = current_user.payment_methods.order(is_default: :desc, created_at: :desc)
    @stripe_publishable_key = Rails.configuration.stripe[:publishable_key]
  end

  def new
    @payment_method = current_user.payment_methods.new
    @stripe_publishable_key = Rails.configuration.stripe[:publishable_key]
  end

  def create
    stripe_pm_id = params[:stripe_payment_method_id]
    
    unless stripe_pm_id.present?
      redirect_to new_dashboard_payment_method_path, alert: "Please provide payment method details."
      return
    end

    begin
      # Use StripeService to attach payment method
      set_as_default = params[:is_default] == "1" || current_user.payment_methods.none?
      StripeService.attach_payment_method(
        user: current_user,
        payment_method_id: stripe_pm_id,
        set_as_default: set_as_default
      )
      
      redirect_to dashboard_payment_methods_path, notice: "Payment method added successfully."
    rescue StripeService::StripeError => e
      redirect_to new_dashboard_payment_method_path, alert: "Unable to add payment method: #{e.message}"
    end
  end

  def set_default
    begin
      # Update Stripe customer default payment method
      StripeService.attach_payment_method(
        user: current_user,
        payment_method_id: @payment_method.stripe_payment_method_id,
        set_as_default: true
      )

      # Update local records
      current_user.payment_methods.update_all(is_default: false)
      @payment_method.update(is_default: true)

      redirect_to dashboard_payment_methods_path, notice: "Default payment method updated."
    rescue StripeService::StripeError => e
      redirect_to dashboard_payment_methods_path, alert: "Error updating default payment method: #{e.message}"
    end
  end

  def destroy
    # Don't allow deleting the default payment method if there's an active subscription
    if @payment_method.is_default? && current_user.subscriptions.active.exists?
      redirect_to dashboard_payment_methods_path, alert: "Cannot remove default payment method while you have an active subscription."
      return
    end

    begin
      # Use StripeService to detach payment method
      StripeService.detach_payment_method(@payment_method.stripe_payment_method_id)
      
      # Delete local record
      @payment_method.destroy
      
      redirect_to dashboard_payment_methods_path, notice: "Payment method removed successfully."
    rescue StripeService::StripeError => e
      redirect_to dashboard_payment_methods_path, alert: "Error removing payment method: #{e.message}"
    end
  end

  private

  def set_payment_method
    @payment_method = current_user.payment_methods.find(params[:id])
  end
end
