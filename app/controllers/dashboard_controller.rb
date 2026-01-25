class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    @subscription = current_user.subscriptions
      .active_subscriptions
      .includes(:subscription_plan)
      .order(created_at: :desc)
      .first || current_user.subscriptions
        .includes(:subscription_plan)
        .order(created_at: :desc)
        .first
    @recent_orders = current_user.orders.recent.limit(5)
    @addresses = current_user.addresses
    @payment_methods = current_user.payment_methods
  end
end
