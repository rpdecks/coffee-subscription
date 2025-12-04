class Admin::OrdersController < Admin::BaseController
  include CsvExportable

  before_action :set_order, only: [ :show, :update_status ]

  def index
    @orders = build_orders_query

    respond_to do |format|
      format.html { @pagy, @orders = pagy(@orders, items: 25) }
      format.csv { export_orders_csv }
    end
  end

  def export
    @orders = build_orders_query
    export_orders_csv
  end

  def show
    @order_items = @order.order_items.includes(:product)
  end

  def update_status
    old_status = @order.status
    new_status = params[:status]

    if new_status.blank?
      flash[:alert] = "Status parameter is required."
      redirect_to admin_order_path(@order)
      return
    end

    if @order.update(status: new_status)
      # Send email notifications based on status changes
      case @order.status
      when "processing"
        OrderMailer.order_confirmation(@order).deliver_later
      when "roasting"
        OrderMailer.order_roasting(@order).deliver_later
      when "shipped"
        @order.update(shipped_at: Time.current) unless @order.shipped_at
        OrderMailer.order_shipped(@order).deliver_later
      when "delivered"
        @order.update(delivered_at: Time.current) unless @order.delivered_at
        OrderMailer.order_delivered(@order).deliver_later
      end

      flash[:notice] = "Order status updated from #{old_status} to #{@order.status}."
      redirect_to admin_order_path(@order)
    else
      flash[:alert] = "Unable to update order status: #{@order.errors.full_messages.join(', ')}"
      redirect_to admin_order_path(@order)
    end
  end

  private

  def build_orders_query
    orders = Order.includes(:user, :subscription, :shipping_address).order(created_at: :desc)

    # Filter by status if provided
    if params[:status].present? && Order.statuses.key?(params[:status])
      orders = orders.where(status: params[:status])
    end

    # Search by order number or customer name
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      orders = orders.references(:user).where(
        "LOWER(orders.order_number) LIKE LOWER(?) OR LOWER(users.first_name) LIKE LOWER(?) OR LOWER(users.last_name) LIKE LOWER(?) OR LOWER(users.email) LIKE LOWER(?)",
        search_term, search_term, search_term, search_term
      )
    end

    orders
  end

  def export_orders_csv
    render_csv(@orders, "orders") do |csv, orders|
      csv << [ "Order Number", "Customer Name", "Email", "Date", "Status", "Type", "Total", "Shipping Address" ]

      orders.each do |order|
        csv << [
          order.order_number,
          order.user.full_name,
          order.user.email,
          order.created_at.strftime("%Y-%m-%d"),
          order.status.titleize,
          order.order_type.titleize,
          sprintf("%.2f", order.total_cents / 100.0),
          format_address(order)
        ]
      end
    end
  end

  def format_address(order)
    return "N/A" unless order.shipping_address

    address = order.shipping_address
    parts = [
      address.street_address,
      address.city,
      address.state,
      address.zip_code
    ].compact

    parts.join(", ")
  end

  def set_order
    @order = Order.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to admin_orders_path, alert: "Order not found."
  end

  def order_params
    params.require(:order).permit(:status, :tracking_number)
  end
end
