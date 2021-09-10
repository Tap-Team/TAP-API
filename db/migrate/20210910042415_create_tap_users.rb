class CreateTapUsers < ActiveRecord::Migration[6.1]
  def change
    create_table :tap_users do |t|
      t.string :uid
      t.string :wallet_id
      t.timestamps
    end
  end
end
