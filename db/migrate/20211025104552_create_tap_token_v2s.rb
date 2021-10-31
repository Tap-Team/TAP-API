class CreateTapTokenV2s < ActiveRecord::Migration[6.1]
  def change
    create_table :tap_token_v2s, id: false do |t|
      t.string :token_id, primary_key: true
      t.string :tx_id
      t.timestamps
    end
  end
end
