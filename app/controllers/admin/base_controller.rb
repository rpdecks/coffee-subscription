class Admin::BaseController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin!

  layout "admin"

  private

  def require_admin!
    return if current_user&.admin?

    raise Pundit::NotAuthorizedError, "You must be an administrator to access this area."
  end
end
