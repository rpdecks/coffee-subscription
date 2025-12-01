class Admin::OrdersController < Admin::BaseController
  before_action :set_order, only: [:show, :update_status]

  def index
    @orders = Order.includes(:user, :subscription).order(created_at: :desc)
    
    # Filter by status if provided
    if params[:status].present? && Order.statuses.key?(params[:status])
      @orders = @orders.where(status: params[:status])
    end
    
    # Search by order number or customer name
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      @orders = @orders.joins(:user).where(
        "orders.order_number LIKE ? OR users.first_name LIKE ? OR users.last_name LIKE ? OR users.email LIKE ?",
        search_term, search_term, search_term, search_term
      )
    end
    
    @orders = @orders.limit(100) # Show up to 100 orders
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
