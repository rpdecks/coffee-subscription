class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("DEFAULT_FROM_EMAIL", "Acer Coffee <hello@acercoffee.com>"),
          reply_to: ENV.fetch("SUPPORT_EMAIL", "support@acercoffee.com")
  layout "mailer"
end
