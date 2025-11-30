class PagesController < ApplicationController
  def home
  end

  def about
  end

  def faq
  end

  def contact
  end

  def create_contact
    # Honeypot check - if "website" field is filled, it's a bot
    if params[:website].present?
      Rails.logger.info "Honeypot triggered for IP: #{request.ip}"
      flash[:notice] = "Thank you for your message. We'll get back to you soon!"
      redirect_to contact_path
      return
    end

    # Time check - reject submissions faster than 3 seconds
    if params[:form_loaded_at].present?
      time_taken = Time.current.to_i - params[:form_loaded_at].to_i
      if time_taken < 3
        Rails.logger.info "Fast submission detected (#{time_taken}s) for IP: #{request.ip}"
        flash[:alert] = "Please take your time filling out the form."
        redirect_to contact_path
        return
      end
    end

    # TODO: Implement actual email sending
    # ContactMailer.contact_form(
    #   name: params[:name],
    #   email: params[:email],
    #   subject: params[:subject],
    #   message: params[:message]
    # ).deliver_later

    flash[:notice] = "Thank you for your message. We'll get back to you soon!"
    redirect_to contact_path
  end
end
