class AddCreatorUserToSecrets < ActiveRecord::Migration[8.0]
  def change
    add_reference :secrets, :creator_user, null: true, foreign_key: { to_table: :users }
  end
end
