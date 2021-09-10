class CreateTapTokens < ActiveRecord::Migration[6.1]
  def change
    create_table :tap_tokens do |t|
      t.string :token_id
      t.string :data
      t.timestamps
    end
  end
end
