# frozen_string_literal: true

class DeviseMailer < Devise::Mailer
  layout "mailer"

  # Ensure URL helpers work in mailer views
  include Devise::Controllers::UrlHelpers
  helper :application

  default reply_to: ENV.fetch("SUPPORT_EMAIL", "support@acercoffee.com")

  def reset_password_instructions(record, token, opts = {})
    disable_sendgrid_click_tracking!
    super
  end

  def confirmation_instructions(record, token, opts = {})
    disable_sendgrid_click_tracking!
    super
  end

  def unlock_instructions(record, token, opts = {})
    disable_sendgrid_click_tracking!
    super
  end

  private

  def disable_sendgrid_click_tracking!
    # SendGrid (SMTP) click tracking can rewrite links to a branded tracking domain.
    # If that domain's TLS is misconfigured, users see a browser cert error.
    # For authentication flows, keep links direct.
    headers["X-SMTPAPI"] = {
      filters: {
        clicktrack: {
          settings: {
            enable: 0
          }
        }
      }
    }.to_json
  end
end
