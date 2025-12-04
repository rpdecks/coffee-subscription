class AddStripeInvoiceIdToOrders < ActiveRecord::Migration[8.1]
  def change
    add_column :orders, :stripe_invoice_id, :string
  end
end
