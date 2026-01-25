class OrderMailer < ApplicationMailer
  default from: ENV.fetch("ORDERS_FROM_EMAIL", "Acer Coffee <orders@acercoffee.com>"),
          reply_to: ENV.fetch("SUPPORT_EMAIL", "support@acercoffee.com")

  def order_confirmation(order)
    @order = order
    @customer = order.user
    @items = order.order_items.includes(:product)

    mail(
      to: @customer.email,
      subject: "Order Confirmation - #{@order.order_number}"
    )
  end

  def order_roasting(order)
    @order = order
    @customer = order.user

    mail(
      to: @customer.email,
      subject: "Your coffee is being roasted! - #{@order.order_number}"
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
