# frozen_string_literal: true

class ManualSaleRecorder
  Result = Struct.new(:success?, :order, :errors, keyword_init: true)

  def initialize(params:)
    @params = params.to_h.deep_symbolize_keys
    @errors = []
  end

  def call
    ActiveRecord::Base.transaction do
      validate_params!
      ensure_transaction_reference_unused!

      product = Product.find(params[:product_id])
      quantity = params[:quantity].to_i
      payment = stripe_payment_details
      user = find_or_create_user!(payment)
      address = find_or_create_address!(user, payment)

      decrement_inventory!(product, quantity)

      @order = user.orders.create!(
        order_type: :one_time,
        status: order_status,
        shipping_address: address,
        stripe_payment_intent_id: normalized_transaction_reference
      )

      @order.order_items.create!(product: product, quantity: quantity, price_cents: product.price_cents)
      @order.calculate_totals
      @order.shipped_at = Time.current if order_status == "shipped"
      @order.delivered_at = Time.current if order_status == "delivered"
      @order.save!
    end

    Result.new(success?: true, order: @order, errors: [])
  rescue ActiveRecord::RecordInvalid => e
    Result.new(success?: false, order: @order, errors: [ e.record.errors.full_messages.to_sentence.presence || e.message ])
  rescue StandardError => e
    Result.new(success?: false, order: @order, errors: [ e.message ])
  end

  private

  attr_reader :params

  def validate_params!
    raise "Product is required" if params[:product_id].blank?
    raise "Quantity must be greater than 0" unless params[:quantity].to_i.positive?
    raise "Status is invalid" unless Order.statuses.key?(order_status)
  end

  def ensure_transaction_reference_unused!
    return if normalized_transaction_reference.blank?
    return unless Order.exists?(stripe_payment_intent_id: normalized_transaction_reference)

    raise "That Stripe transaction has already been imported"
  end

  def order_status
    params[:status].presence || "delivered"
  end

  def stripe_payment_details
    return nil if params[:transaction_reference].blank?

    reference = params[:transaction_reference].strip

    payment_intent = case reference
    when /\Api_/
      Stripe::PaymentIntent.retrieve({ id: reference, expand: [ "latest_charge" ] })
    when /\Ach_/
      charge = Stripe::Charge.retrieve(reference)
      if charge.payment_intent.present?
        Stripe::PaymentIntent.retrieve({ id: charge.payment_intent, expand: [ "latest_charge" ] })
      else
        OpenStruct.new(id: charge.id, latest_charge: charge, customer: nil)
      end
    else
      raise "Stripe reference must start with pi_ or ch_"
    end

    charge = payment_intent.latest_charge
    billing = charge&.billing_details

    {
      payment_intent_id: payment_intent.id,
      customer_id: payment_intent.customer,
      email: billing&.email,
      name: billing&.name,
      phone: billing&.phone,
      address: billing&.address
    }
  rescue Stripe::StripeError => e
    raise "Unable to load Stripe transaction: #{e.message}"
  end

  def normalized_transaction_reference
    @normalized_transaction_reference ||= stripe_payment_details&.dig(:payment_intent_id).presence || params[:transaction_reference].presence
  end

  def find_or_create_user!(payment)
    email = params[:customer_email].presence || payment&.dig(:email)
    raise "Customer email is required" if email.blank?

    user = User.find_by(email: email)
    return update_user_from_payment!(user, payment) if user.present?

    first_name, last_name = split_name(params[:customer_name].presence || payment&.dig(:name) || email)
    password = SecureRandom.base58(24)

    user = User.new(
      email: email,
      first_name: first_name,
      last_name: last_name,
      phone: params[:customer_phone].presence || payment&.dig(:phone),
      password: password,
      password_confirmation: password,
      stripe_customer_id: payment&.dig(:customer_id)
    )
    user.skip_confirmation!
    user.save!
    user
  end

  def update_user_from_payment!(user, payment)
    updates = {}
    updates[:phone] = params[:customer_phone].presence || payment&.dig(:phone) if user.phone.blank?
    updates[:stripe_customer_id] = payment&.dig(:customer_id) if user.stripe_customer_id.blank? && payment&.dig(:customer_id).present?
    user.update!(updates) if updates.any?
    user
  end

  def find_or_create_address!(user, payment)
    address_attributes = {
      street_address: params[:street_address].presence || payment&.dig(:address)&.line1,
      street_address_2: params[:street_address_2].presence || payment&.dig(:address)&.line2,
      city: params[:city].presence || payment&.dig(:address)&.city,
      state: params[:state].presence || payment&.dig(:address)&.state,
      zip_code: params[:zip_code].presence || payment&.dig(:address)&.postal_code,
      country: params[:country].presence || payment&.dig(:address)&.country || "US"
    }

    if address_attributes.values_at(:street_address, :city, :state, :zip_code, :country).all?(&:present?)
      existing = user.addresses.find_by(
        street_address: address_attributes[:street_address],
        street_address_2: address_attributes[:street_address_2],
        city: address_attributes[:city],
        state: address_attributes[:state],
        zip_code: address_attributes[:zip_code],
        country: address_attributes[:country]
      )
      return existing if existing.present?

      return user.addresses.create!(address_attributes.merge(address_type: :shipping))
    end

    user.addresses.shipping.first || user.addresses.first || raise("Shipping address is required")
  end

  def decrement_inventory!(product, quantity)
    if product.coffee?
      decrement_packaged_inventory!(product, quantity)
    else
      decrement_merch_inventory!(product, quantity)
    end
  end

  def decrement_packaged_inventory!(product, quantity)
    raise "Coffee bag size must be configured before recording a sale" unless product.weight_oz.to_f.positive?

    pounds_to_decrement = (product.weight_oz.to_d * quantity) / 16
    packaged_items = product.inventory_items.packaged.available.order(:roasted_on, :created_at)
    remaining = pounds_to_decrement

    if packaged_items.sum(:quantity).to_d < pounds_to_decrement
      raise "Not enough packaged inventory available to record this sale"
    end

    packaged_items.each do |item|
      break if remaining <= 0

      current_quantity = item.quantity.to_d
      deduction = [ current_quantity, remaining ].min
      item.update!(quantity: current_quantity - deduction)
      remaining -= deduction
    end
  end

  def decrement_merch_inventory!(product, quantity)
    return if product.inventory_count.nil?
    raise "Not enough inventory available to record this sale" if product.inventory_count < quantity

    product.update!(inventory_count: product.inventory_count - quantity)
  end

  def split_name(name)
    parts = name.to_s.strip.split
    first_name = parts.first.presence || "Customer"
    last_name = parts.drop(1).join(" ").presence || "Order"
    [ first_name, last_name ]
  end
end
