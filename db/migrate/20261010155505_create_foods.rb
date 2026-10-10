class CreateFoods < ActiveRecord::Migration[8.1]
  def change
    create_table :foods do |t|
      t.references :category, null: false, foreign_key: true
      t.string :name, null: false
      t.string :unit, null: false, default: "lbs"
      t.decimal :yearly_amount_per_person, precision: 14, scale: 4
      t.decimal :package_amount, precision: 14, scale: 4
      t.decimal :package_price, precision: 10, scale: 2

      t.timestamps
    end
    add_index :foods, :name, unique: true
  end
end
