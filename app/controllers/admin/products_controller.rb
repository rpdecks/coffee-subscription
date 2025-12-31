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
    attrs = product_params
    uploaded_images = attrs.delete(:images)

    @product = Product.new(attrs)

    if @product.save
      skipped = attach_images(@product, uploaded_images)
      ensure_image_order_and_featured(@product)

      if skipped.any?
        flash[:alert] = "Skipped duplicate filenames: #{skipped.uniq.join(', ')}"
      end

      redirect_to admin_product_path(@product), notice: "Product created successfully."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    attrs = product_params
    uploaded_images = attrs.delete(:images)

    if @product.update(attrs)
      skipped = attach_images(@product, uploaded_images)
      ensure_image_order_and_featured(@product)

      if skipped.any?
        flash[:alert] = "Skipped duplicate filenames: #{skipped.uniq.join(', ')}"
      end

      redirect_to admin_product_path(@product), notice: "Product updated successfully."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy_image
    @product = Product.find(params[:product_id] || params[:id])
    attachment_id = params[:attachment_id].to_i

    attachment = @product.image_attachments.find { |a| a.id == attachment_id }
    unless attachment
      redirect_to edit_admin_product_path(@product), alert: "Image not found."
      return
    end

    was_featured = @product.featured_image_attachment_id.present? && @product.featured_image_attachment_id.to_i == attachment.id
    attachment.purge

    @product.update_column(:featured_image_attachment_id, nil) if was_featured
    ensure_image_order_and_featured(@product)

    redirect_to edit_admin_product_path(@product), notice: "Image removed."
  end

  def make_featured_image
    @product = Product.find(params[:product_id] || params[:id])
    attachment_id = params[:attachment_id].to_i

    attachment = @product.image_attachments.find { |a| a.id == attachment_id }
    unless attachment
      redirect_to edit_admin_product_path(@product), alert: "Image not found."
      return
    end

    current_order = @product.ordered_image_attachments.map(&:id)
    new_order = ([attachment.id] + current_order).uniq

    @product.update_columns(
      featured_image_attachment_id: attachment.id,
      image_attachment_ids_order: new_order
    )

    redirect_to edit_admin_product_path(@product), notice: "Featured image updated."
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
    permitted = params.require(:product).permit(
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
      :image,
      images: []
    )

    if permitted[:images].is_a?(Array)
      permitted[:images].reject!(&:blank?)
      permitted.delete(:images) if permitted[:images].empty?
    end

    permitted
  end

  def attach_images(product, uploaded_images)
    return [] if uploaded_images.blank?

    require "set"

    existing_filenames = product.image_attachments.map { |a| a.blob&.filename&.to_s }.compact
    seen = Set.new(existing_filenames.map { |n| n.downcase })

    to_attach = []
    skipped = []

    Array(uploaded_images).each do |file|
      filename = if file.respond_to?(:original_filename)
        file.original_filename.to_s
      else
        file.to_s
      end

      key = filename.downcase
      if seen.include?(key)
        skipped << filename
        next
      end

      seen.add(key)
      to_attach << file
    end

    product.images.attach(to_attach) if to_attach.any?
    skipped
  end

  def ensure_image_order_and_featured(product)
    product.reload

    ordered = product.ordered_image_attachments
    if ordered.empty?
      product.update_column(:featured_image_attachment_id, nil)
      product.update_column(:image_attachment_ids_order, [])
      return
    end

    desired_order = ordered.map(&:id)
    desired_featured_id = desired_order.first

    updates = {}
    updates[:image_attachment_ids_order] = desired_order if product.image_attachment_ids_order.map(&:to_i) != desired_order
    updates[:featured_image_attachment_id] = desired_featured_id if product.featured_image_attachment_id.to_i != desired_featured_id.to_i
    product.update_columns(updates) if updates.any?
  end
end
