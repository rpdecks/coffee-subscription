class Admin::SuppliersController < Admin::BaseController
  before_action :set_supplier, only: [ :show, :edit, :update, :destroy ]

  def index
    @suppliers = Supplier.alphabetical

    if params[:search].present?
      @suppliers = @suppliers.where("name ILIKE ?", "%#{params[:search]}%")
    end

    @pagy, @suppliers = pagy(@suppliers, items: 25)
  end

  def show
    @green_coffees = @supplier.green_coffees.recent
    @pagy, @green_coffees = pagy(@green_coffees, items: 25)
  end

  def new
    @supplier = Supplier.new
  end

  def create
    @supplier = Supplier.new(supplier_params)

    if @supplier.save
      redirect_to admin_supplier_path(@supplier), notice: "Supplier created successfully."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @supplier.update(supplier_params)
      redirect_to admin_supplier_path(@supplier), notice: "Supplier updated successfully."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    if @supplier.destroy
      redirect_to admin_suppliers_path, notice: "Supplier deleted successfully."
    else
      redirect_to admin_supplier_path(@supplier), alert: @supplier.errors.full_messages.to_sentence
    end
  end

  private

  def set_supplier
    @supplier = Supplier.find(params[:id])
  end

  def supplier_params
    params.require(:supplier).permit(:name, :url, :contact_name, :contact_email, :notes)
  end
end
