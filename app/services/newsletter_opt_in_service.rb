# frozen_string_literal: true

class NewsletterOptInService
  def self.subscribe(email:)
    email = email.to_s.strip.downcase
    return false if email.blank?
    return false unless email.match?(URI::MailTo::EMAIL_REGEXP)
    return false unless ButtondownService.configured?

    ButtondownService.subscribe(email: email)
  rescue => e
    Rails.logger.warn("Newsletter opt-in failed for #{email.inspect}: #{e.class}: #{e.message}")
    false
  end
end
