class Dashboard::OrdersController < ApplicationController
  before_action :authenticate_user!

  def index
    @orders = current_user.orders.includes(:order_items).order(created_at: :desc)
  end

  def show
    @order = current_user.orders.includes(order_items: :product).find(params[:id])
  end
end
