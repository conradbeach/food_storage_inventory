class CreateItems < ActiveRecord::Migration[8.1]
  def change
    create_table :items do |t|
      t.references :food, null: false, foreign_key: true
      t.string :description
      t.decimal :amount, precision: 14, scale: 4
      t.date :expires_on
      t.datetime :expiration_notified_at

      t.timestamps
    end
    add_index :items, :expires_on
  end
end
