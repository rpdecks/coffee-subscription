# frozen_string_literal: true

class DeviseMailer < Devise::Mailer
  layout "mailer"

  # Ensure URL helpers work in mailer views
  include Devise::Controllers::UrlHelpers
  helper :application

  default reply_to: ENV.fetch("SUPPORT_EMAIL", "support@acercoffee.com")
end
