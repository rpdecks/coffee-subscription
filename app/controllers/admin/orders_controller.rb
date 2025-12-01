class Admin::OrdersController < Admin::BaseController
  include CsvExportable
  
  before_action :set_order, only: [:show, :update_status]

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

  private

  def build_orders_query_orders_query
    orders = Order.includes(:user, :subscription).order(created_at: :desc)
    
    # Filter by status if provided
    if params[:status].present? && Order.statuses.key?(params[:status])
      orders = orders.where(status: params[:status])
    end
    
    # Search by order number or customer name
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      orders = orders.joins(:user).where(
        "orders.order_number LIKE ? OR users.first_name LIKE ? OR users.last_name LIKE ? OR users.email LIKE ?",
        search_term, search_term, search_term, search_term
      )
    end
    
    orders
  end

  def export_orders_csv
    render_csv(@orders, 'orders') do |csv, orders|
      csv << ['Order Number', 'Customer Name', 'Email', 'Date', 'Status', 'Type', 'Total', 'Shipping Address']
      
      orders.each do |order|
        csv << [
          order.order_number,
          order.user.full_name,
          order.user.email,
          order.created_at.strftime('%Y-%m-%d'),
          order.status.titleize,
          order.order_type.titleize,
          sprintf('%.2f', order.total_cents / 100.0),
          format_address(order)
        ]
      end
    end
  end

  def format_address(order)
    return 'N/A' unless order.shipping_address_line1.present?
    
    parts = [
      order.shipping_address_line1,
      order.shipping_address_line2,
      order.shipping_city,
      order.shipping_state,
      order.shipping_zip
    ].compact
    
    parts.join(', ')
  end

  def show
    @order_items = @order.order_items.includes(:product)
  end

  def update_status
    old_status = @order.status
    
    if @order.update(order_params)
      # Set timestamps based on status changes
      case @order.status
      when 'shipped'
        @order.update(shipped_at: Time.current) unless @order.shipped_at
        OrderMailer.order_shipped(@order).deliver_later
      when 'delivered'
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

  def set_order
    @order = Order.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to admin_orders_path, alert: "Order not found."
  end

  def order_params
    params.require(:order).permit(:status, :tracking_number)
  end
end
