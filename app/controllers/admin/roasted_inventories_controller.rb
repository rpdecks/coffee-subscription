class Admin::RoastedInventoriesController < Admin::BaseController
  def new
    @roasted_inventory = InventoryItem.new(state: :roasted)
    @products = Product.coffee.order(:name)
  end

  def create
    @roasted_inventory = InventoryItem.new(roasted_inventory_params)
    @roasted_inventory.state = :roasted

    if @roasted_inventory.save
      redirect_to admin_inventory_index_path, notice: "Roasted inventory recorded"
    else
      @products = Product.coffee.order(:name)
      render :new, status: :unprocessable_content
    end
  end

  private

  def roasted_inventory_params
    params.require(:inventory_item).permit(
      :product_id,
      :quantity,
      :roasted_on,
      :batch_id,
      :notes,
      :lot_number,
      :expires_on
    )
  end
end
