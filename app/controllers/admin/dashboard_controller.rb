class Admin::DashboardController < Admin::BaseController
  def index
    # Overview metrics
    @total_customers = User.customer.count
    @active_subscriptions = Subscription.active.count
    @total_revenue = Order.sum(:total_cents)
    @pending_orders = Order.pending.count

    # Recent activity
    @recent_orders = Order.includes(:user).order(created_at: :desc).limit(10)
    @recent_subscriptions = Subscription.includes(:user, :subscription_plan).order(created_at: :desc).limit(10)

    # Status breakdowns
    @subscriptions_by_status = Subscription.group(:status).count
    @orders_by_status = Order.group(:status).count
  end
end
