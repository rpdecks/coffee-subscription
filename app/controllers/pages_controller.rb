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
    # TODO: Implement contact form submission
    # This will send an email and/or save to database
    flash[:notice] = "Thank you for your message. We'll get back to you soon!"
    redirect_to contact_path
  end
end
