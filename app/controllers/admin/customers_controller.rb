class Admin::CustomersController < Admin::BaseController
  include CsvExportable

  before_action :set_customer, only: [ :show ]

  def index
    @customers = build_customers_query
    @pagy, @customers = pagy(@customers, items: 25)

    respond_to do |format|
      format.html
      format.csv { export_customers_csv }
    end
  end

  def export
    export_customers_csv
  end

  def show
    @subscriptions = @customer.subscriptions.order(created_at: :desc)
    @orders = @customer.orders.order(created_at: :desc).limit(10)
    @addresses = @customer.addresses.order(created_at: :desc)
    @payment_methods = @customer.payment_methods.order(created_at: :desc)
  end

  private

  def build_customers_query
    customers = User.where(role: :customer).order(created_at: :desc)

    if params[:search].present?
      customers = customers.where(
        "first_name ILIKE ? OR last_name ILIKE ? OR email ILIKE ?",
        "%#{params[:search]}%",
        "%#{params[:search]}%",
        "%#{params[:search]}%"
      )
    end

    if params[:status].present?
      case params[:status]
      when "active_subscription"
        customers = customers.joins(:subscriptions).where(subscriptions: { status: :active }).distinct
      when "no_subscription"
        customers = customers.left_joins(:subscriptions).where(subscriptions: { id: nil })
      end
    end

    customers
  end

  def export_customers_csv
    customers = build_customers_query.includes(:subscriptions, :orders)

    render_csv(customers, "customers") do |csv, customers|
      csv << [ "Name", "Email", "Phone", "Subscriptions", "Total Orders", "Total Spent", "Joined Date" ]

      customers.each do |customer|
        csv << [
          customer.full_name,
          customer.email,
          customer.phone || "N/A",
          customer.subscriptions.count,
          customer.orders.count,
          sprintf("%.2f", customer.orders.sum(:total_cents) / 100.0),
          customer.created_at.strftime("%Y-%m-%d")
        ]
      end
    end
  end

  def set_customer
    @customer = User.find(params[:id])
  end
end
