class CreatePeople < ActiveRecord::Migration[8.1]
  def change
    create_table :people do |t|
      t.string :name, null: false
      t.integer :calories_per_day, null: false

      t.timestamps
    end
  end
end
