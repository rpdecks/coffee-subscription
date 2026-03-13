class Admin::CustomerReviewsController < Admin::BaseController
  before_action :set_customer_review, only: [ :edit, :update, :destroy, :toggle_approval, :toggle_about_featured ]
  before_action :load_products, only: [ :index, :new, :create, :edit, :update ]

  def index
    @customer_reviews = CustomerReview.includes(:product).newest_first

    if params[:product_id] == "general"
      @customer_reviews = @customer_reviews.where(product_id: nil)
    elsif params[:product_id].present?
      @customer_reviews = @customer_reviews.where(product_id: params[:product_id])
    end

    case params[:status]
    when "approved"
      @customer_reviews = @customer_reviews.approved
    when "pending"
      @customer_reviews = @customer_reviews.pending
    when "featured"
      @customer_reviews = @customer_reviews.approved.featured_on_about
    end
  end

  def new
    @customer_review = CustomerReview.new(product_id: params[:product_id])
  end

  def create
    @customer_review = CustomerReview.new(customer_review_params)

    if @customer_review.save
      redirect_to admin_customer_reviews_path(product_id: @customer_review.product_id.presence), notice: "Review saved successfully."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @customer_review.update(customer_review_params)
      redirect_to admin_customer_reviews_path(product_id: @customer_review.product_id.presence), notice: "Review updated successfully."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @customer_review.destroy
    redirect_to admin_customer_reviews_path(product_id: params[:product_id].presence), notice: "Review deleted."
  end

  def toggle_approval
    becoming_approved = !@customer_review.approved?
    @customer_review.update!(approved: becoming_approved)

    redirect_to admin_customer_reviews_path(product_id: params[:product_id].presence), notice: "Review #{becoming_approved ? 'approved' : 'moved back to pending'}"
  end

  def toggle_about_featured
    updates = { featured_on_about: !@customer_review.featured_on_about? }
    updates[:approved] = true if updates[:featured_on_about]
    @customer_review.update!(updates)

    redirect_to admin_customer_reviews_path(product_id: params[:product_id].presence), notice: "About page highlighting updated."
  end

  private

  def set_customer_review
    @customer_review = CustomerReview.find(params[:id])
  end

  def load_products
    @products = Product.order(:name)
  end

  def customer_review_params
    permitted = params.require(:customer_review).permit(
      :product_id,
      :customer_name,
      :location,
      :headline,
      :body,
      :rating,
      :approved,
      :featured_on_about,
      :sort_position
    )

    permitted[:product_id] = nil if permitted[:product_id].blank?
    permitted
  end
end
