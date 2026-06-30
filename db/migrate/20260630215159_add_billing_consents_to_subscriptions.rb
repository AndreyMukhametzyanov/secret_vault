class AddBillingConsentsToSubscriptions < ActiveRecord::Migration[8.0]
  def change
    add_column :subscriptions, :pro_terms_accepted_at, :datetime
    add_column :subscriptions, :auto_renew_consent_at, :datetime
    add_column :subscriptions, :payment_partner_consent_at, :datetime
  end
end
