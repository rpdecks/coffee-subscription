class Admin::InventoryController < Admin::BaseController
  before_action :set_inventory_item, only: [ :edit, :update, :destroy ]

  def index
    @inventory_items = InventoryItem.includes(:product).recent

    # Filter by product type
    if params[:product_type].present?
      product_ids = Product.where(product_type: params[:product_type]).pluck(:id)
      @inventory_items = @inventory_items.where(product_id: product_ids)
    end

    # Filter by state (green, roasted, packaged)
    if params[:state].present?
      @inventory_items = @inventory_items.where(state: params[:state])
    end

    # Filter by stock status
    case params[:stock_status]
    when "available"
      @inventory_items = @inventory_items.available
    when "low_stock"
      @inventory_items = @inventory_items.low_stock
    when "out_of_stock"
      @inventory_items = @inventory_items.out_of_stock
    when "expiring_soon"
      @inventory_items = @inventory_items.expiring_soon
    end

    # Search by product name or lot number
    if params[:search].present?
      product_ids = Product.where("name ILIKE ?", "%#{params[:search]}%").pluck(:id)
      @inventory_items = @inventory_items.where(
        "product_id IN (?) OR lot_number ILIKE ?",
        product_ids,
        "%#{params[:search]}%"
      )
    end

    # Sort
    case params[:sort]
    when "quantity_asc"
      @inventory_items = @inventory_items.reorder(quantity: :asc)
    when "quantity_desc"
      @inventory_items = @inventory_items.reorder(quantity: :desc)
    when "roast_date"
      @inventory_items = @inventory_items.by_roast_date
    when "received_date"
      @inventory_items = @inventory_items.by_received_date
    else
      @inventory_items = @inventory_items.recent
    end

    @pagy, @inventory_items = pagy(@inventory_items, items: 25)

    # Calculate summary stats
    @total_items = InventoryItem.count
    @low_stock_count = InventoryItem.low_stock.count
    @expiring_soon_count = InventoryItem.expiring_soon.count
    @out_of_stock_count = InventoryItem.out_of_stock.count
  end

  def new
    @inventory_item = InventoryItem.new
    @products = Product.all.order(:name)
  end

  def create
    @inventory_item = InventoryItem.new(inventory_item_params)

    if @inventory_item.save
      redirect_to admin_inventory_index_path, notice: "Inventory item created successfully."
    else
      @products = Product.all.order(:name)
      render :new, status: :unprocessable_content
    end
  end

  def edit
    @products = Product.all.order(:name)
  end

  def update
    if @inventory_item.update(inventory_item_params)
      redirect_to admin_inventory_index_path, notice: "Inventory item updated successfully."
    else
      @products = Product.all.order(:name)
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @inventory_item.destroy
    redirect_to admin_inventory_index_path, notice: "Inventory item deleted successfully."
  end

  private

  def set_inventory_item
    @inventory_item = InventoryItem.find(params[:id])
  end

  def inventory_item_params
    params.require(:inventory_item).permit(
      :product_id,
      :state,
      :quantity,
      :lot_number,
      :roasted_on,
      :received_on,
      :expires_on,
      :notes,
      :batch_id
    )
  end
end
