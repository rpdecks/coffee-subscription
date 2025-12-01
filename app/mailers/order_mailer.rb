class OrderMailer < ApplicationMailer
  default from: ENV.fetch('SENDGRID_FROM_EMAIL', 'orders@coffeeshop.com')

  def order_confirmation(order)
    @order = order
    @customer = order.user
    @items = order.order_items.includes(:product)
    
    mail(
      to: @customer.email,
      subject: "Order Confirmation - #{@order.order_number}"
    )
  end

  def order_shipped(order)
    @order = order
    @customer = order.user
    @tracking_number = order.tracking_number if order.respond_to?(:tracking_number)
    
    mail(
      to: @customer.email,
      subject: "Your order has shipped! - #{@order.order_number}"
    )
  end

  def order_delivered(order)
    @order = order
    @customer = order.user
    
    mail(
      to: @customer.email,
      subject: "Your order has been delivered - #{@order.order_number}"
    )
  end
end
