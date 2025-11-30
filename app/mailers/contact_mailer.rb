class ContactMailer < ApplicationMailer
  default from: ENV['SENDGRID_FROM_EMAIL'] || 'rpdecks@gmail.com'

  def contact_form(name:, email:, subject:, message:)
    @name = name
    @email = email
    @subject = subject
    @message = message

    mail(
      to: ENV['CONTACT_EMAIL'] || 'hello@coffeeco.com',
      reply_to: email,
      subject: "Contact Form: #{subject}"
    )
  end
end
