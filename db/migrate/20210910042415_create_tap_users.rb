class CreateTapUsers < ActiveRecord::Migration[6.1]
  def change
    create_table :tap_users, id: false do |t|
      t.string :uid, primary_key: true
      t.string :wallet_id
      t.timestamps
    end
  end
end
