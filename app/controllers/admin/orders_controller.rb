class Admin::OrdersController < Admin::BaseController
  include CsvExportable

  before_action :set_order, only: [ :show, :update_status ]
  before_action :load_manual_sale_form, only: [ :new, :create ]

  def index
    load_order_summary
    orders = build_orders_query
    @pagy, @orders = pagy(orders, items: 25)

    respond_to do |format|
      format.html
      format.csv { export_orders_csv }
    end
  end

  def export
    export_orders_csv
  end

  def new
  end

  def create
    @manual_sale = manual_sale_params.to_h
    result = ManualSaleRecorder.new(params: manual_sale_params).call

    if result.success?
      redirect_to admin_order_path(result.order), notice: "Manual sale recorded successfully."
    else
      @manual_sale_errors = result.errors
      render :new, status: :unprocessable_content
    end
  end

  def show
    @order_items = @order.order_items.includes(:product)
  end

  def update_status
    old_status = @order.status
    update_attributes = order_status_update_attributes
    new_status = update_attributes[:status]

    if new_status.blank?
      flash[:alert] = "Status parameter is required."
      redirect_to admin_order_path(@order)
      return
    end

    if apply_status_update(@order, update_attributes)
      flash[:notice] = "Order status updated from #{old_status} to #{@order.status}."
      redirect_to admin_order_path(@order)
    else
      flash[:alert] = "Unable to update order status: #{@order.errors.full_messages.join(', ')}"
      redirect_to admin_order_path(@order)
    end
  end

  def bulk_update_status
    order_ids = bulk_order_ids
    target_status = bulk_target_status

    if order_ids.empty?
      redirect_to admin_orders_path(orders_index_redirect_params), alert: "Select at least one order to update."
      return
    end

    if target_status.blank?
      redirect_to admin_orders_path(orders_index_redirect_params), alert: "Choose a status for the bulk update."
      return
    end

    orders = Order.where(id: order_ids).order(:created_at)
    updated_orders = []
    failed_orders = []

    orders.each do |order|
      if apply_status_update(order, status: target_status)
        updated_orders << order.order_number
      else
        failed_orders << "#{order.order_number} (#{order.errors.full_messages.join(', ')})"
      end
    end

    if updated_orders.any?
      flash[:notice] = "Updated #{updated_orders.size} #{'order'.pluralize(updated_orders.size)} to #{target_status.titleize}."
    end

    if failed_orders.any?
      flash[:alert] = "Some orders were not updated: #{failed_orders.join('; ')}"
    end

    redirect_to admin_orders_path(orders_index_redirect_params)
  end

  private

  def load_manual_sale_form
    @products = Product.active.order(:name)
    @manual_sale ||= { "status" => "delivered", "country" => "US" }
    @manual_sale_errors ||= []
  end

  def build_orders_query
    orders = Order.includes(:user, :subscription, :shipping_address)

    orders = apply_queue_filter(orders)

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

    apply_sort(orders)
  end

  def export_orders_csv
    orders = build_orders_query.includes(:user, :subscription, :shipping_address)
    render_csv(orders, "orders") do |csv, orders|
      csv << [ "Order Number", "Customer Name", "Email", "Date", "Status", "Type", "Total", "Shipping Address" ]

      orders.each do |order|
        csv << [
          order.order_number,
          order.user.full_name,
          order.user.email,
          order.created_at.strftime("%Y-%m-%d"),
          order.status.titleize,
          order.order_type.titleize,
          sprintf("%.2f", order.total),
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

  def load_order_summary
    counts = Order.group(:status).count
    @status_counts = Order.statuses.keys.index_with do |status|
      counts[status] || counts[status.to_sym] || counts[Order.statuses[status]] || 0
    end
    @fulfillment_count = Order.pending_fulfillment.count
    @delivered_today_count = Order.delivered_today.count
    @stale_fulfillment_count = Order.pending_fulfillment.count(&:stale_fulfillment?)
    @critical_fulfillment_count = Order.pending_fulfillment.count(&:critical_fulfillment?)
  end

  def manual_sale_params
    params.fetch(:manual_sale, {}).permit(
      :transaction_reference,
      :product_id,
      :quantity,
      :status,
      :customer_name,
      :customer_email,
      :customer_phone,
      :street_address,
      :street_address_2,
      :city,
      :state,
      :zip_code,
      :country
    )
  end

  def order_params
    params.require(:order).permit(:status, :tracking_number)
  end

  def order_status_update_attributes
    attributes = {}
    attributes[:status] = params.dig(:order, :status) || params[:status]

    tracking_number = params.dig(:order, :tracking_number) || params[:tracking_number]
    attributes[:tracking_number] = tracking_number if tracking_number.present?

    attributes
  end

  def apply_queue_filter(orders)
    case params[:queue]
    when "fulfillment"
      orders.pending_fulfillment
    when "delivered_today"
      orders.delivered_today
    else
      orders
    end
  end

  def apply_sort(orders)
    if params[:queue] == "fulfillment"
      orders.order(created_at: :asc)
    else
      orders.order(created_at: :desc)
    end
  end

  def apply_status_update(order, update_attributes)
    previous_status = order.status

    if order.update(update_attributes)
      apply_status_side_effects(order, previous_status)
      true
    else
      false
    end
  end

  def apply_status_side_effects(order, previous_status)
    return if previous_status == order.status

    case order.status
    when "processing"
      OrderMailer.order_confirmation(order).deliver_later
    when "roasting"
      OrderMailer.order_roasting(order).deliver_later
    when "shipped"
      order.update(shipped_at: Time.current) unless order.shipped_at
      OrderMailer.order_shipped(order).deliver_later
    when "delivered"
      order.update(delivered_at: Time.current) unless order.delivered_at
      OrderMailer.order_delivered(order).deliver_later
    end
  end

  def bulk_order_ids
    params.fetch(:bulk, {}).fetch(:order_ids, []).reject(&:blank?)
  end

  def bulk_target_status
    params.fetch(:bulk, {})[:status]
  end

  def orders_index_redirect_params
    params.permit(:search, :status, :queue, :page).to_h.compact_blank
  end
end
