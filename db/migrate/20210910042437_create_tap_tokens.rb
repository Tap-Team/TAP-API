class CreateTapTokens < ActiveRecord::Migration[6.1]
  def change
    create_table :tap_tokens, id: false do |t|
      t.string :token_id, primary_key: true
      t.string :data
      t.timestamps
    end
  end
end
