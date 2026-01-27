class NewsletterSubscriptionsController < ApplicationController
  def create
    email = params[:email].to_s.strip.downcase

    unless email.match?(URI::MailTo::EMAIL_REGEXP)
      flash[:alert] = "Please enter a valid email address."
      redirect_to root_path(anchor: "newsletter")
      return
    end

    unless ButtondownService.configured?
      Rails.logger.error("Buttondown API key missing; cannot subscribe #{email}")
      flash[:alert] = "Newsletter signup is temporarily unavailable. Please try again later."
      redirect_to root_path(anchor: "newsletter")
      return
    end

    if ButtondownService.subscribe(email: email)
      flash[:notice] = "Almost done — check your inbox to confirm your subscription."
      redirect_to newsletter_thanks_path
    else
      flash[:alert] = "Sorry — we couldn't subscribe you right now. Please try again in a minute."
      redirect_to newsletter_thanks_path
    end
  end
end
