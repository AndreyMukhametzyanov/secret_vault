class CreateSubscriptionsAndBillingPayments < ActiveRecord::Migration[8.0]
  def change
    create_table :subscriptions do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.string :status, null: false, default: "pending"
      t.string :yookassa_payment_method_id
      t.datetime :current_period_ends_at
      t.boolean :auto_renew, null: false, default: true
      t.datetime :canceled_at

      t.timestamps
    end

    create_table :billing_payments do |t|
      t.references :user, null: false, foreign_key: true
      t.string :yookassa_payment_id, null: false
      t.integer :amount_cents, null: false
      t.string :currency, null: false, default: "RUB"
      t.string :status, null: false, default: "pending"
      t.string :purpose, null: false
      t.json :metadata

      t.timestamps
    end

    add_index :billing_payments, :yookassa_payment_id, unique: true
  end
end
