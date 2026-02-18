class Admin::RoastedInventoriesController < Admin::BaseController
  def new
    prefill = params[:prefill] || {}

    green_weight_used = prefill[:green_weight_used]
    if green_weight_used.blank?
      source_item = InventoryItem.find_by(id: prefill[:source_inventory_item_id])
      green_weight_used = parse_green_weight_used(source_item&.notes)
    end

    if green_weight_used.blank? && prefill[:product_id].present?
      green_weight_used = last_green_weight_used_for_product(prefill[:product_id])
    end

    @roasted_inventory = InventoryItem.new(state: :roasted, roasted_on: Date.today)
    @prefill = {
      product_id: prefill[:product_id],
      green_weight_used: green_weight_used,
      roasted_weight: prefill[:roasted_weight],
      lot_number: prefill[:lot_number],
      batch_id: prefill[:batch_id]
    }.compact
    load_products
  end

  def create
    rp = record_roast_params
    product = Product.find_by(id: rp[:product_id])

    result = RecordRoastService.new(
      product: product,
      roasted_weight: rp[:roasted_weight],
      green_weight_used: rp[:green_weight_used],
      roasted_on: rp[:roasted_on],
      lot_number: rp[:lot_number],
      batch_id: rp[:batch_id],
      notes: rp[:notes],
      expires_on: rp[:expires_on]
    ).call

    if result.success?
      flash_parts = [ "Roasted inventory recorded: #{result.roasted_item.quantity} lbs." ]
      if result.green_deductions.any?
        total_debited = result.green_deductions.sum(&:amount_debited).round(2)
        green_remaining = product.total_green_inventory.round(2)
        flash_parts << "Green debited: #{total_debited} lbs (#{green_remaining} lbs remaining)."
      end
      flash_parts << "Weight loss: #{result.weight_loss_pct}%."
      if result.errors.any?
        flash_parts << result.errors.join(" ")
      end
      redirect_to admin_inventory_index_path, notice: flash_parts.join(" ")
    else
      flash.now[:alert] = result.errors.join(". ")
      @roasted_inventory = InventoryItem.new(state: :roasted)
      @prefill = {}
      load_products
      render :new, status: :unprocessable_content
    end
  end

  private

  def record_roast_params
    params.require(:record_roast).permit(
      :product_id, :roasted_weight, :green_weight_used,
      :roasted_on, :lot_number, :batch_id, :notes, :expires_on
    )
  end

  def load_products
    @products = Product.coffee.order(:name)
    @green_inventory_by_product = InventoryItem.green
      .where(product_id: @products.select(:id))
      .group(:product_id)
      .sum(:quantity)
  end

  def parse_green_weight_used(notes)
    notes.to_s.match(/Green used:\s*([\d.]+)/i)&.captures&.first
  end

  def last_green_weight_used_for_product(product_id)
    pid = product_id.to_i
    return nil if pid <= 0

    InventoryItem.roasted
      .where(product_id: pid)
      .where("notes ILIKE ?", "%Green used:%")
      .order(created_at: :desc)
      .limit(20)
      .pluck(:notes)
      .filter_map { |n| parse_green_weight_used(n) }
      .first
  end
end
