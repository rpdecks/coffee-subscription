class Dashboard::ProfilesController < ApplicationController
  before_action :authenticate_user!

  def edit
    @user = current_user
  end

  def update
    @user = current_user

    if user_params[:password].present?
      # If updating password, require current password
      if @user.update_with_password(user_params)
        bypass_sign_in(@user) # Sign in the user again to maintain session
        redirect_to edit_dashboard_profile_path, notice: "Profile updated successfully."
      else
        render :edit, status: :unprocessable_content
      end
    else
      # If not updating password, just update other attributes
      if @user.update_without_password(user_params.except(:current_password, :password, :password_confirmation))
        redirect_to edit_dashboard_profile_path, notice: "Profile updated successfully."
      else
        render :edit, status: :unprocessable_content
      end
    end
  end

  private

  def user_params
    params.require(:user).permit(:first_name, :last_name, :email, :phone, :current_password, :password, :password_confirmation)
  end
end
