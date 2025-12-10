class Admin::ProductsController < Admin::BaseController
  before_action :set_product, only: [ :show, :edit, :update, :destroy, :toggle_active, :toggle_shop_visibility ]

  def index
    @products = Product.all.order(created_at: :desc)

    if params[:search].present?
      @products = @products.where("name ILIKE ?", "%#{params[:search]}%")
    end

    if params[:product_type].present?
      @products = @products.where(product_type: params[:product_type])
    end

    if params[:status].present?
      case params[:status]
      when "active"
        @products = @products.where(active: true)
      when "inactive"
        @products = @products.where(active: false)
      when "in_stock"
        @products = @products.where("inventory_count IS NULL OR inventory_count > 0")
      when "out_of_stock"
        @products = @products.where("inventory_count IS NOT NULL AND inventory_count <= 0")
      end
    end

    @pagy, @products = pagy(@products, items: 25)
  end

  def show
  end

  def new
    @product = Product.new
  end

  def create
    @product = Product.new(product_params)

    if @product.save
      redirect_to admin_product_path(@product), notice: "Product created successfully."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @product.update(product_params)
      redirect_to admin_product_path(@product), notice: "Product updated successfully."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @product.destroy
    redirect_to admin_products_path, notice: "Product deleted successfully."
  end

  def toggle_active
    @product.update(active: !@product.active)
    redirect_to admin_products_path, notice: "Product #{@product.active? ? 'activated' : 'deactivated'}."
  end

  def toggle_shop_visibility
    @product.update(visible_in_shop: !@product.visible_in_shop)
    redirect_to admin_products_path, notice: "Product #{@product.visible_in_shop? ? 'shown' : 'hidden'} in shop."
  end

  private

  def set_product
    @product = Product.find(params[:id])
  end

  def product_params
    params.require(:product).permit(
      :name,
      :description,
      :product_type,
      :roast_type,
      :price,
      :weight_oz,
      :inventory_count,
      :active,
      :visible_in_shop,
      :stripe_product_id,
      :stripe_price_id,
      :image
    )
  end
end
