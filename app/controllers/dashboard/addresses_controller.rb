class Dashboard::AddressesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_address, only: [:edit, :update, :destroy]

  def index
    @addresses = current_user.addresses.order(is_default: :desc, created_at: :desc)
  end

  def new
    @address = current_user.addresses.build(address_type: :shipping, country: "United States")
  end

  def create
    @address = current_user.addresses.build(address_params)
    
    if @address.save
      redirect_to dashboard_addresses_path, notice: "Address added successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @address.update(address_params)
      redirect_to dashboard_addresses_path, notice: "Address updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @address.destroy
    redirect_to dashboard_addresses_path, notice: "Address removed."
  end

  private

  def set_address
    @address = current_user.addresses.find(params[:id])
  end

  def address_params
    params.require(:address).permit(
      :address_type, :street_address, :street_address_2, 
      :city, :state, :zip_code, :country, :is_default
    )
  end
end
