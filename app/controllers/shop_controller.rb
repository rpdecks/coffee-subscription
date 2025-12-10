# frozen_string_literal: true

class ShopController < ApplicationController
  before_action :authenticate_user!, except: [ :index, :show ]

  def index
    @category = params[:category]&.to_sym
    @roast = params[:roast]&.to_sym

    @products = Product.active.visible_in_shop.in_stock

    case @category
    when :coffee
      @products = @products.coffee
    when :merch
      @products = @products.merch
    end

    # Filter by roast type if specified
    if @roast.present? && Product.roast_types.key?(@roast.to_s)
      @products = @products.where(roast_type: @roast)
    end

    @products = @products.order(:name)
  end

  def show
    @product = Product.find(params[:id])
    redirect_to shop_path, alert: "Product not available" unless @product.active? && @product.visible_in_shop? && @product.in_stock?
  end

  def checkout
    unless current_user
      store_location_for(:user, shop_checkout_path)
      redirect_to new_user_session_path, alert: "Please sign in to continue"
      return
    end

    @cart_items = session[:cart] || []
    if @cart_items.empty?
      redirect_to shop_path, alert: "Your cart is empty"
      return
    end

    # Load products from cart
    @products_with_quantities = @cart_items.map do |item|
      product = Product.find_by(id: item["product_id"])
      next unless product&.active? && product&.in_stock?

      { product: product, quantity: item["quantity"] }
    end.compact

    if @products_with_quantities.empty?
      redirect_to shop_path, alert: "No valid items in cart"
      return
    end

    # Calculate totals
    @subtotal = @products_with_quantities.sum { |item| item[:product].price * item[:quantity] }
    @shipping = calculate_shipping(@products_with_quantities)
    @tax = 0 # TODO: Calculate tax based on shipping address
    @total = @subtotal + @shipping + @tax
  end

  def create_checkout_session
    unless current_user
      render json: { error: "Unauthorized" }, status: :unauthorized
      return
    end

    cart_items = params[:cart_items] || []
    if cart_items.empty?
      render json: { error: "Cart is empty" }, status: :unprocessable_entity
      return
    end

    # Build cart items with products
    items_with_products = cart_items.map do |item|
      product = Product.find_by(id: item[:product_id])
      next unless product&.active? && product&.in_stock?

      { product: product, quantity: item[:quantity].to_i }
    end.compact

    if items_with_products.empty?
      render json: { error: "No valid products in cart" }, status: :unprocessable_entity
      return
    end

    # Create Stripe checkout session
    session = StripeService.create_product_checkout_session(
      user: current_user,
      cart_items: items_with_products,
      success_url: shop_success_url,
      cancel_url: shop_checkout_url,
      metadata: {
        cart_items: cart_items.to_json
      }
    )

    render json: { checkout_url: session.url }
  rescue StripeService::StripeError => e
    Rails.logger.error("Checkout session creation failed: #{e.message}")
    render json: { error: "Unable to create checkout session" }, status: :unprocessable_entity
  end

  def success
    @order = current_user.orders.one_time.recent.first
  end

  def add_to_cart
    product_id = params[:product_id]
    quantity = params[:quantity].to_i
    quantity = 1 if quantity < 1

    product = Product.find_by(id: product_id)
    unless product&.active? && product&.in_stock?
      redirect_to shop_path, alert: "Product not available"
      return
    end

    session[:cart] ||= []
    existing_item = session[:cart].find { |item| item["product_id"] == product_id.to_s }

    if existing_item
      existing_item["quantity"] = (existing_item["quantity"].to_i + quantity).to_s
    else
      session[:cart] << { "product_id" => product_id.to_s, "quantity" => quantity.to_s }
    end

    redirect_to shop_path, notice: "#{product.name} added to cart"
  end

  def remove_from_cart
    product_id = params[:product_id]
    session[:cart] ||= []
    session[:cart].reject! { |item| item["product_id"] == product_id.to_s }

    redirect_to shop_checkout_path, notice: "Item removed from cart"
  end

  def update_cart
    product_id = params[:product_id]
    quantity = params[:quantity].to_i

    session[:cart] ||= []
    if quantity <= 0
      session[:cart].reject! { |item| item["product_id"] == product_id.to_s }
    else
      item = session[:cart].find { |i| i["product_id"] == product_id.to_s }
      item["quantity"] = quantity.to_s if item
    end

    redirect_to shop_checkout_path
  end

  def clear_cart
    session[:cart] = []
    redirect_to shop_path, notice: "Cart cleared"
  end

  private

  def calculate_shipping(items)
    # TODO: Implement real shipping calculation
    # For now, flat rate shipping
    5.00
  end
end
