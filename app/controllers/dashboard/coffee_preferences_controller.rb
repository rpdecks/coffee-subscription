class Dashboard::CoffeePreferencesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_coffee_preference

  def edit
  end

  def update
    if @coffee_preference.update(coffee_preference_params)
      redirect_to dashboard_root_path, notice: "Coffee preferences updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_coffee_preference
    @coffee_preference = current_user.coffee_preference || current_user.build_coffee_preference
  end

  def coffee_preference_params
    params.require(:coffee_preference).permit(:roast_level, :grind_type, :flavor_notes, :special_instructions)
  end
end
