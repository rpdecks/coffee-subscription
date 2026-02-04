# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  before_action :configure_sign_up_params, only: [ :create ]
  before_action :configure_account_update_params, only: [ :update ]

  SMTP_DELIVERY_ERRORS = [
    Net::SMTPAuthenticationError,
    Net::SMTPServerBusy,
    Net::SMTPFatalError,
    Net::SMTPSyntaxError,
    EOFError,
    OpenSSL::SSL::SSLError,
    SocketError
  ].freeze

  def create
    super do |resource|
      next unless resource&.persisted?

      opt_in = ActiveModel::Type::Boolean.new.cast(params.dig(:user, :newsletter_opt_in))
      next unless opt_in

      NewsletterOptInService.subscribe(email: resource.email)
    end
  rescue *SMTP_DELIVERY_ERRORS => e
    Rails.logger.error("Signup confirmation email delivery failed: #{e.class}: #{e.message}")

    flash[:alert] = "We created your account, but couldn't send the confirmation email. Please try again later or contact support."
    redirect_to root_path
  end

  protected

  # If you have extra params to permit, append them to the sanitizer.
  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :first_name, :last_name, :phone, :newsletter_opt_in ])
  end

  # If you have extra params to permit, append them to the sanitizer.
  def configure_account_update_params
    devise_parameter_sanitizer.permit(:account_update, keys: [ :first_name, :last_name, :phone, :avatar ])
  end

  # The path used after sign up.
  def after_sign_up_path_for(resource)
    dashboard_root_path
  end

  # The path used after sign up for inactive accounts.
  # def after_inactive_sign_up_path_for(resource)
  #   super(resource)
  # end
end
