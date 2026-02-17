class Admin::BlendComponentsController < Admin::BaseController
  before_action :set_product
  before_action :set_blend_component, only: [ :edit, :update, :destroy ]

  def new
    @blend_component = @product.blend_components.build
    @green_coffees = available_green_coffees
  end

  def create
    @blend_component = @product.blend_components.build(blend_component_params)

    if @blend_component.save
      redirect_to admin_product_path(@product), notice: "Blend component added."
    else
      @green_coffees = available_green_coffees
      render :new, status: :unprocessable_content
    end
  end

  def edit
    @green_coffees = available_green_coffees(exclude: @blend_component.green_coffee_id)
  end

  def update
    if @blend_component.update(blend_component_params)
      redirect_to admin_product_path(@product), notice: "Blend component updated."
    else
      @green_coffees = available_green_coffees(exclude: @blend_component.green_coffee_id)
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @blend_component.destroy
    redirect_to admin_product_path(@product), notice: "Blend component removed."
  end

  private

  def set_product
    @product = Product.find(params[:product_id])
  end

  def set_blend_component
    @blend_component = @product.blend_components.find(params[:id])
  end

  def blend_component_params
    params.require(:blend_component).permit(:green_coffee_id, :percentage)
  end

  def available_green_coffees(exclude: nil)
    used_ids = @product.blend_components.where.not(green_coffee_id: exclude).pluck(:green_coffee_id)
    GreenCoffee.where.not(id: used_ids).includes(:supplier).order(:name)
  end
end
