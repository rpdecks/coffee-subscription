class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    @subscription = current_user.subscriptions.active_subscriptions.first
    @recent_orders = current_user.orders.recent.limit(5)
    @addresses = current_user.addresses
    @payment_methods = current_user.payment_methods
  end
end
