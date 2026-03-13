class Dashboard::ProfilesController < ApplicationController
  before_action :authenticate_user!

  def edit
    @user = current_user
  end

  def update
    @user = current_user
    remove_avatar = params[:user][:avatar_remove] == "true"

    update_params = user_params
    update_params = update_params.except(:avatar) if remove_avatar

    if params[:user][:password].present?
      password_params = {
        password: params[:user][:password],
        password_confirmation: params[:user][:password_confirmation],
        current_password: params[:user][:current_password]
      }
      success = @user.update_with_password(update_params.merge(password_params))
    else
      success = @user.update(update_params)
    end

    if success
      @user.avatar.purge if remove_avatar && @user.avatar.attached?
      bypass_sign_in(@user) if params[:user][:password].present?
      redirect_to edit_dashboard_profile_path, notice: "Profile updated successfully."
    else
      render :edit, status: :unprocessable_content
    end
  end

  private

  def user_params
    params.require(:user).permit(:first_name, :last_name, :email, :phone, :avatar)
  end
end
