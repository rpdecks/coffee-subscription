class Dashboard::ProfilesController < ApplicationController
  before_action :authenticate_user!

  def edit
    @user = current_user
  end

  def update
    @user = current_user

    # Handle avatar removal first if checkbox is checked
    if params[:user][:avatar_remove] == "true"
      @user.avatar.purge if @user.avatar.attached?
    end

    # Handle avatar upload separately BEFORE other updates
    if params[:user][:avatar].present? && params[:user][:avatar_remove] != "true"
      uploaded_file = params[:user][:avatar]
      @user.avatar.attach(
        io: uploaded_file.open,
        filename: uploaded_file.original_filename,
        content_type: uploaded_file.content_type
      )
    end

    # Prepare params without avatar
    update_params = user_params

    # Handle password vs non-password updates
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
      bypass_sign_in(@user) if params[:user][:password].present?
      redirect_to edit_dashboard_profile_path, notice: "Profile updated successfully."
    else
      render :edit, status: :unprocessable_content
    end
  end

  private

  def user_params
    params.require(:user).permit(:first_name, :last_name, :email, :phone)
  end
end
