class Admin::SubscriptionPlansController < Admin::BaseController
  before_action :set_subscription_plan, only: [:show, :edit, :update, :destroy, :toggle_active]

  def index
    @subscription_plans = SubscriptionPlan.all.order(frequency: :asc, created_at: :desc)
  end

  def show
    @subscriptions_count = @subscription_plan.subscriptions.count
    @active_subscriptions_count = @subscription_plan.subscriptions.active.count
  end

  def new
    @subscription_plan = SubscriptionPlan.new
  end

  def create
    @subscription_plan = SubscriptionPlan.new(subscription_plan_params)
    
    if @subscription_plan.save
      redirect_to admin_subscription_plan_path(@subscription_plan), notice: "Subscription plan created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @subscription_plan.update(subscription_plan_params)
      redirect_to admin_subscription_plan_path(@subscription_plan), notice: "Subscription plan updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @subscription_plan.subscriptions.any?
      redirect_to admin_subscription_plans_path, alert: "Cannot delete plan with active subscriptions."
    else
      @subscription_plan.destroy
      redirect_to admin_subscription_plans_path, notice: "Subscription plan deleted successfully."
    end
  end

  def toggle_active
    @subscription_plan.update(active: !@subscription_plan.active)
    redirect_to admin_subscription_plans_path, notice: "Plan #{@subscription_plan.active? ? 'activated' : 'deactivated'}."
  end

  private

  def set_subscription_plan
    @subscription_plan = SubscriptionPlan.find(params[:id])
  end

  def subscription_plan_params
    params.require(:subscription_plan).permit(
      :name,
      :description,
      :frequency,
      :bags_per_delivery,
      :price,
      :stripe_plan_id,
      :active
    )
  end
end
