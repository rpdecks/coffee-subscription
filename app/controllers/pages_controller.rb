class PagesController < ApplicationController
  def home
    hero_images = [
      "hero/coffee-cherries-1.jpg",
      "hero/coffee-cherries-2.jpg",
      "hero/coffee-cherries-3.jpg"
    ]

    hero_index = params[:hero].to_i
    hero_index = 3 unless hero_index.between?(1, hero_images.length)

    @hero_image = hero_images[hero_index - 1]
    @featured_products = Product.coffee.active.visible_in_shop.with_attached_image.order(:name).limit(3)
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

    # Send email
    begin
      ContactMailer.contact_form(
        name: params[:name],
        email: params[:email],
        subject: params[:subject],
        message: params[:message]
      ).deliver_later

      flash[:notice] = "Thank you for your message. We'll get back to you soon!"
    rescue => e
      Rails.logger.error "Failed to send contact email: #{e.message}"
      flash[:alert] = "Sorry, there was an error sending your message. Please try again later."
    end

    redirect_to contact_path
  end

  def thank_you
  end

  def newsletter_thanks
  end
end
