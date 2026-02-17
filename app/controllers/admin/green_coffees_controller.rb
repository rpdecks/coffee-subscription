class Admin::GreenCoffeesController < Admin::BaseController
  before_action :set_green_coffee, only: [ :show, :edit, :update, :destroy ]

  def index
    @green_coffees = GreenCoffee.includes(:supplier, :blend_components).recent

    if params[:search].present?
      @green_coffees = @green_coffees.where(
        "green_coffees.name ILIKE ? OR green_coffees.lot_number ILIKE ? OR green_coffees.origin_country ILIKE ?",
        "%#{params[:search]}%", "%#{params[:search]}%", "%#{params[:search]}%"
      )
    end

    if params[:supplier_id].present?
      @green_coffees = @green_coffees.where(supplier_id: params[:supplier_id])
    end

    if params[:freshness].present?
      case params[:freshness]
      when "fresh"
        @green_coffees = @green_coffees.where("harvest_date > ?", GreenCoffee::FRESH_MONTHS.months.ago)
      when "good"
        @green_coffees = @green_coffees.where("harvest_date > ? AND harvest_date <= ?",
          GreenCoffee::GOOD_MONTHS.months.ago, GreenCoffee::FRESH_MONTHS.months.ago)
      when "aging"
        @green_coffees = @green_coffees.where("harvest_date > ? AND harvest_date <= ?",
          GreenCoffee::PAST_CROP_MONTHS.months.ago, GreenCoffee::GOOD_MONTHS.months.ago)
      when "past_crop"
        @green_coffees = @green_coffees.where("harvest_date <= ?", GreenCoffee::PAST_CROP_MONTHS.months.ago)
      end
    end

    if params[:stock].present?
      case params[:stock]
      when "in_stock"
        @green_coffees = @green_coffees.in_stock
      when "out_of_stock"
        @green_coffees = @green_coffees.out_of_stock
      end
    end

    @pagy, @green_coffees = pagy(@green_coffees, items: 25)
    @suppliers = Supplier.alphabetical

    # Summary stats
    @total_lbs = GreenCoffee.sum(:quantity_lbs)
    @total_lots = GreenCoffee.count
    @in_stock_count = GreenCoffee.in_stock.count
    @past_crop_count = GreenCoffee.where("harvest_date <= ?", GreenCoffee::PAST_CROP_MONTHS.months.ago).count
  end

  def show
    @blend_components = @green_coffee.blend_components.includes(:product)
  end

  def new
    @green_coffee = GreenCoffee.new
    @suppliers = Supplier.alphabetical
  end

  def create
    @green_coffee = GreenCoffee.new(green_coffee_params)

    if @green_coffee.save
      redirect_to admin_green_coffee_path(@green_coffee), notice: "Green coffee added successfully."
    else
      @suppliers = Supplier.alphabetical
      render :new, status: :unprocessable_content
    end
  end

  def edit
    @suppliers = Supplier.alphabetical
  end

  def update
    if @green_coffee.update(green_coffee_params)
      redirect_to admin_green_coffee_path(@green_coffee), notice: "Green coffee updated successfully."
    else
      @suppliers = Supplier.alphabetical
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    if @green_coffee.destroy
      redirect_to admin_green_coffees_path, notice: "Green coffee deleted successfully."
    else
      redirect_to admin_green_coffee_path(@green_coffee), alert: @green_coffee.errors.full_messages.to_sentence
    end
  end

  private

  def set_green_coffee
    @green_coffee = GreenCoffee.find(params[:id])
  end

  def green_coffee_params
    params.require(:green_coffee).permit(
      :supplier_id, :name, :origin_country, :region, :variety,
      :process, :harvest_date, :arrived_on, :cost_per_lb,
      :quantity_lbs, :lot_number, :notes
    )
  end
end
