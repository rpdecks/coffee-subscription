class ContactMailer < ApplicationMailer
  default from: "Acer Coffee <orders@acercoffee.com>"

  def contact_form(name:, email:, subject:, message:)
    @name = name
    @email = email
    @subject = subject
    @message = message

    mail(
      to: "orders@acercoffee.com",
      reply_to: email,
      subject: "Contact Form: #{subject}"
    )
  end
end
