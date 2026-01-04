# frozen_string_literal: true

class Users::ConfirmationsController < Devise::ConfirmationsController
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
    super
  rescue *SMTP_DELIVERY_ERRORS => e
    Rails.logger.error("Confirmation email delivery failed: #{e.class}: #{e.message}")

    flash[:alert] = "We couldn't send the confirmation email right now. Please try again later or contact support."
    redirect_to new_user_confirmation_path
  end
end
