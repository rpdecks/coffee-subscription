class ContactMailer < ApplicationMailer
  default from: ENV.fetch("SUPPORT_FROM_EMAIL", "Acer Coffee <support@acercoffee.com>")

  def contact_form(name:, email:, subject:, message:)
    @name = name
    @email = email
    @subject = subject
    @message = message

    mail(
      to: ENV.fetch("SUPPORT_EMAIL", "support@acercoffee.com"),
      reply_to: email,
      subject: "Contact Form: #{subject}"
    )
  end
end
