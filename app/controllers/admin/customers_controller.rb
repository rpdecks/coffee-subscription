class Admin::CustomersController < Admin::BaseController
  before_action :set_customer, only: [:show]

  def index
    @customers = User.where(role: :customer).order(created_at: :desc)
    
    if params[:search].present?
      @customers = @customers.where(
        "first_name ILIKE ? OR last_name ILIKE ? OR email ILIKE ?",
        "%#{params[:search]}%",
        "%#{params[:search]}%",
        "%#{params[:search]}%"
      )
    end
    
    if params[:status].present?
      case params[:status]
      when 'active_subscription'
        @customers = @customers.joins(:subscriptions).where(subscriptions: { status: :active }).distinct
      when 'no_subscription'
        @customers = @customers.left_joins(:subscriptions).where(subscriptions: { id: nil })
      end
    end
    
    @pagy, @customers = pagy(@customers, items: 25)
  end

  def show
    @subscriptions = @customer.subscriptions.order(created_at: :desc)
    @orders = @customer.orders.order(created_at: :desc).limit(10)
    @addresses = @customer.addresses.order(created_at: :desc)
    @payment_methods = @customer.payment_methods.order(created_at: :desc)
  end

  private

  def set_customer
    @customer = User.find(params[:id])
  end
end
