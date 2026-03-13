class CustomerReviewsController < ApplicationController
  def create
    @product = Product.active.find(params[:product_id])
    @customer_review = @product.customer_reviews.build(customer_review_params)

    if @customer_review.save
      redirect_to product_path(@product), notice: "Thanks for sharing your review. It will appear after approval."
    else
      @approved_reviews = @product.customer_reviews.approved.display_order
      render "products/show", status: :unprocessable_content
    end
  rescue ActiveRecord::RecordNotFound
    flash[:alert] = "Product not found"
    redirect_to products_path
  end

  private

  def customer_review_params
    params.require(:customer_review).permit(:customer_name, :location, :headline, :body, :rating)
  end
end