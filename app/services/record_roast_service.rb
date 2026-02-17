# frozen_string_literal: true

class RecordRoastService
  Result = Struct.new(:success?, :roasted_item, :green_deductions, :weight_loss_pct, :errors, keyword_init: true)

  GreenDeduction = Struct.new(:inventory_item, :amount_debited, :remaining, keyword_init: true)

  def initialize(product:, roasted_weight:, green_weight_used:, roasted_on:, lot_number: nil, batch_id: nil, notes: nil, expires_on: nil)
    @product = product
    @roasted_weight = roasted_weight.to_f
    @green_weight_used = green_weight_used.to_f
    @roasted_on = roasted_on
    @lot_number = lot_number
    @batch_id = batch_id
    @notes = notes
    @expires_on = expires_on
    @errors = []
    @green_deductions = []
  end

  def call
    validate!
    return failure_result if @errors.any?

    ActiveRecord::Base.transaction do
      create_roasted_item!
      debit_green_inventory!
    end

    success_result
  rescue ActiveRecord::RecordInvalid => e
    @errors << e.message
    failure_result
  end

  private

  attr_reader :product, :roasted_weight, :green_weight_used, :roasted_on,
              :lot_number, :batch_id, :notes, :expires_on

  def validate!
    @errors << "Product is required" if product.nil?
    @errors << "Roasted weight must be greater than zero" unless roasted_weight.positive?
    @errors << "Green weight used must be greater than zero" unless green_weight_used.positive?
    @errors << "Green weight must be greater than roasted weight (roasting causes weight loss)" if green_weight_used <= roasted_weight && green_weight_used.positive? && roasted_weight.positive?
    @errors << "Roast date is required" if roasted_on.blank?
  end

  def create_roasted_item!
    @roasted_item = InventoryItem.create!(
      product: product,
      state: :roasted,
      quantity: roasted_weight,
      roasted_on: roasted_on,
      lot_number: lot_number,
      batch_id: batch_id,
      notes: build_notes,
      expires_on: expires_on
    )
  end

  def debit_green_inventory!
    green_items = product.inventory_items.green.available.order(:received_on, :created_at)
    remaining_to_debit = green_weight_used

    green_items.each do |item|
      break if remaining_to_debit <= 0

      debit_amount = [ item.quantity, remaining_to_debit ].min
      new_quantity = item.quantity - debit_amount
      item.update!(quantity: new_quantity)

      @green_deductions << GreenDeduction.new(
        inventory_item: item,
        amount_debited: debit_amount,
        remaining: new_quantity
      )

      remaining_to_debit -= debit_amount
    end

    if remaining_to_debit.positive?
      @errors << "Warning: #{remaining_to_debit.round(2)} lbs of green coffee could not be debited (insufficient green inventory)"
    end
  end

  def weight_loss_pct
    return 0.0 unless green_weight_used.positive?
    ((green_weight_used - roasted_weight) / green_weight_used * 100).round(1)
  end

  def build_notes
    parts = []
    parts << notes if notes.present?
    parts << "Green used: #{green_weight_used.round(2)} lbs → Roasted: #{roasted_weight.round(2)} lbs (#{weight_loss_pct}% loss)"
    parts.join("\n")
  end

  def success_result
    Result.new(
      success?: true,
      roasted_item: @roasted_item,
      green_deductions: @green_deductions,
      weight_loss_pct: weight_loss_pct,
      errors: @errors # may contain warnings
    )
  end

  def failure_result
    Result.new(
      success?: false,
      roasted_item: nil,
      green_deductions: [],
      weight_loss_pct: 0.0,
      errors: @errors
    )
  end
end
