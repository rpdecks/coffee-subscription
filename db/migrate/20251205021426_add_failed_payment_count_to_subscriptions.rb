class AddFailedPaymentCountToSubscriptions < ActiveRecord::Migration[8.1]
  def change
    add_column :subscriptions, :failed_payment_count, :integer, default: 0, null: false
  end
end
