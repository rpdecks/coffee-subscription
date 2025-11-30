class ContactMailer < ApplicationMailer
  default from: 'noreply@coffeeco.com'

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
