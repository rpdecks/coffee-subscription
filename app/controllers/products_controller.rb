class ProductsController < ApplicationController
  def index
    @products = Product.active.includes(:product_type).order(:name)
  end

  def show
    @product = Product.active.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    flash[:alert] = "Product not found"
    redirect_to products_path
  end
end
