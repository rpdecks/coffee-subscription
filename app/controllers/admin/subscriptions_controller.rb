class Admin::SubscriptionsController < Admin::BaseController
  before_action :set_subscription, only: [ :show, :edit, :update, :pause, :resume, :cancel ]

  def index
    @subscriptions = Subscription.includes(:user, :subscription_plan).order(created_at: :desc)

    # Filter by status if provided
    if params[:status].present? && Subscription.statuses.key?(params[:status])
      @subscriptions = @subscriptions.where(status: params[:status])
    end

    # Search by customer name or email
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      @subscriptions = @subscriptions.joins(:user).where(
        "users.first_name LIKE ? OR users.last_name LIKE ? OR users.email LIKE ?",
        search_term, search_term, search_term
      )
    end

    @pagy, @subscriptions = pagy(@subscriptions, items: 25)
  end

  def show
    @orders = @subscription.orders.order(created_at: :desc).limit(10)
  end

  def edit
  end

  def update
    if @subscription.update(subscription_params)
      redirect_to admin_subscription_path(@subscription), notice: "Subscription updated successfully."
    else
      flash[:alert] = "Unable to update subscription: #{@subscription.errors.full_messages.join(', ')}"
      render :edit, status: :unprocessable_entity
    end
  end

  def pause
    if @subscription.active?
      @subscription.update(status: :paused)
      SubscriptionMailer.subscription_paused(@subscription).deliver_later
      redirect_to admin_subscription_path(@subscription), notice: "Subscription paused."
    else
      redirect_to admin_subscription_path(@subscription), alert: "Subscription cannot be paused."
    end
  end

  def resume
    if @subscription.paused?
      @subscription.update(status: :active, next_delivery_date: calculate_next_delivery_date)
      SubscriptionMailer.subscription_resumed(@subscription).deliver_later
      redirect_to admin_subscription_path(@subscription), notice: "Subscription resumed. Next delivery: #{@subscription.next_delivery_date.strftime('%B %d, %Y')}."
    else
      redirect_to admin_subscription_path(@subscription), alert: "Subscription cannot be resumed."
    end
  end

  def cancel
    if @subscription.active? || @subscription.paused?
      @subscription.update(status: :cancelled, cancelled_at: Time.current)
      SubscriptionMailer.subscription_cancelled(@subscription).deliver_later
      redirect_to admin_subscription_path(@subscription), notice: "Subscription cancelled."
    else
      redirect_to admin_subscription_path(@subscription), alert: "Subscription cannot be cancelled."
    end
  end

  private

  def set_subscription
    @subscription = Subscription.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to admin_subscriptions_path, alert: "Subscription not found."
  end

  def subscription_params
    params.require(:subscription).permit(
      :subscription_plan_id,
      :shipping_address_id,
      :payment_method_id,
      :bag_size,
      :quantity,
      :next_delivery_date
    )
  end

  def calculate_next_delivery_date
    frequency_days = case @subscription.subscription_plan.frequency
    when "weekly" then 7
    when "biweekly" then 14
    when "monthly" then 30
    end

    Date.today + frequency_days.days
  end
end
