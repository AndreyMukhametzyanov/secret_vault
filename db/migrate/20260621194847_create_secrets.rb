class CreateSecrets < ActiveRecord::Migration[7.0]
  def change
    create_table :secrets, id: false do |t|
      t.string :id, limit: 36, null: false, primary_key: true
      t.text :encrypted_body, null: false
      t.string :password_salt
      t.datetime :expires_at, null: false
      t.integer :max_reads, default: 1
      t.integer :reads_count, default: 0

      t.timestamps
    end
  end
end
