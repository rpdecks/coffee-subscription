# frozen_string_literal: true

class RoastAndPackageInventoryRecorder
  Result = Struct.new(
    :success?,
    :product,
    :green_coffee,
    :roasted_item,
    :packaged_item,
    :green_coffee_debited_lbs,
    :roasted_deductions,
    :errors,
    keyword_init: true
  )

  RoastedDeduction = Struct.new(:inventory_item, :amount_debited, :remaining, keyword_init: true)

  def self.call(params:)
    new(params:).call
  end

  def initialize(params:)
    @params = params.to_h.deep_symbolize_keys
    @errors = []
    @roasted_deductions = []
    @green_coffee_debited_lbs = 0.0
  end

  def call
    validate_params!
    return failure_result if errors.any?

    ActiveRecord::Base.transaction do
      record_roast_if_needed!
      debit_green_coffee_if_needed!
      create_packaged_item_if_needed!
      debit_roasted_inventory_if_needed!
    end

    success_result
  rescue ActiveRecord::RecordInvalid => error
    errors << (error.record.errors.full_messages.to_sentence.presence || error.message)
    failure_result
  rescue StandardError => error
    errors << error.message
    failure_result
  end

  private

  attr_reader :params, :errors, :roasted_deductions, :green_coffee_debited_lbs

  def validate_params!
    errors << "Product is required" if product.nil?

    if roasted_weight <= 0 && packaged_weight <= 0
      errors << "Provide roasted_weight, packaged_weight, or both"
    end

    if roasted_weight.positive?
      errors << "Green weight used must be greater than zero when recording a roast" unless green_weight_used.positive?
      errors << "Green weight must be greater than roasted weight" if green_weight_used.positive? && green_weight_used <= roasted_weight
      errors << "Roast date is required when recording a roast" if roasted_on.blank?
    end

    if packaged_weight.positive?
      errors << "Roast date is required when creating packaged inventory" if roasted_on.blank?
      errors << "Packaged weight must be greater than zero" unless packaged_weight.positive?
    end

    if green_coffee && green_weight_used.positive? && green_coffee.quantity_lbs.to_f < green_weight_used
      errors << "Green coffee only has #{green_coffee.quantity_lbs.to_f.round(2)} lbs available"
    end

    if packaged_weight.positive? && available_roasted_inventory_after_new_roast < packaged_weight
      errors << "Not enough roasted inventory available to package #{packaged_weight.round(2)} lbs"
    end
  end

  def record_roast_if_needed!
    return unless roasted_weight.positive?

    result = RecordRoastService.new(
      product: product,
      roasted_weight: roasted_weight,
      green_weight_used: green_weight_used,
      roasted_on: roasted_on,
      lot_number: lot_number,
      batch_id: batch_id,
      notes: notes,
      expires_on: expires_on
    ).call

    unless result.success?
      raise ActiveRecord::RecordInvalid.new(result.roasted_item || InventoryItem.new), result.errors.to_sentence
    end

    @roasted_item = result.roasted_item
    errors.concat(result.errors)
  end

  def debit_green_coffee_if_needed!
    return unless green_coffee && green_weight_used.positive?

    green_coffee.update!(quantity_lbs: green_coffee.quantity_lbs.to_d - green_weight_used)
    @green_coffee_debited_lbs = green_weight_used
  end

  def create_packaged_item_if_needed!
    return unless packaged_weight.positive?

    @packaged_item = InventoryItem.create!(
      product: product,
      state: :packaged,
      quantity: packaged_weight,
      roasted_on: roasted_on,
      lot_number: lot_number,
      batch_id: batch_id,
      expires_on: expires_on,
      notes: packaging_notes
    )
  end

  def debit_roasted_inventory_if_needed!
    return unless packaged_weight.positive?

    remaining_to_debit = packaged_weight
    roasted_items = product.inventory_items.roasted.available.order(:roasted_on, :created_at)

    roasted_items.each do |item|
      break if remaining_to_debit <= 0

      debit_amount = [ item.quantity.to_d, remaining_to_debit ].min
      new_quantity = item.quantity.to_d - debit_amount
      item.update!(quantity: new_quantity)

      roasted_deductions << RoastedDeduction.new(
        inventory_item: item,
        amount_debited: debit_amount,
        remaining: new_quantity
      )

      remaining_to_debit -= debit_amount
    end

    return unless remaining_to_debit.positive?

    raise "Unable to fully debit roasted inventory; #{remaining_to_debit.round(2)} lbs remain"
  end

  def packaging_notes
    parts = []
    parts << notes if notes.present?
    parts << "Packaged: #{packaged_weight.round(2)} lbs"
    parts << "Green used: #{green_weight_used.round(2)} lbs" if green_weight_used.positive?
    parts.join("\n")
  end

  def available_roasted_inventory_after_new_roast
    product_roasted = product&.total_roasted_inventory.to_d || 0.to_d
    product_roasted + roasted_weight
  end

  def product
    @product ||= Product.find_by(id: params[:product_id])
  end

  def green_coffee
    @green_coffee ||= GreenCoffee.find_by(id: params[:green_coffee_id]) if params[:green_coffee_id].present?
  end

  def roasted_weight
    @roasted_weight ||= normalize_decimal(params[:roasted_weight])
  end

  def packaged_weight
    @packaged_weight ||= normalize_decimal(params[:packaged_weight])
  end

  def green_weight_used
    @green_weight_used ||= normalize_decimal(params[:green_weight_used])
  end

  def roasted_on
    @roasted_on ||= normalize_date(params[:roasted_on])
  end

  def lot_number
    @lot_number ||= clean_string(params[:lot_number])
  end

  def batch_id
    @batch_id ||= clean_string(params[:batch_id])
  end

  def notes
    @notes ||= clean_string(params[:notes])
  end

  def expires_on
    @expires_on ||= normalize_date(params[:expires_on])
  end

  def normalize_decimal(value)
    return 0.to_d if value.blank?

    BigDecimal(value.to_s)
  end

  def normalize_date(value)
    return nil if value.blank?

    value.is_a?(Date) ? value : Date.parse(value.to_s)
  end

  def clean_string(value)
    value.to_s.strip.presence
  end

  def success_result
    Result.new(
      success?: true,
      product: product,
      green_coffee: green_coffee,
      roasted_item: @roasted_item,
      packaged_item: @packaged_item,
      green_coffee_debited_lbs: green_coffee_debited_lbs,
      roasted_deductions: roasted_deductions,
      errors: errors
    )
  end

  def failure_result
    Result.new(
      success?: false,
      product: product,
      green_coffee: green_coffee,
      roasted_item: @roasted_item,
      packaged_item: @packaged_item,
      green_coffee_debited_lbs: green_coffee_debited_lbs,
      roasted_deductions: roasted_deductions,
      errors: errors
    )
  end
end
