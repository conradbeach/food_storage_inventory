class CreateHouseholdSupplies < ActiveRecord::Migration[8.1]
  def change
    create_table :household_supplies do |t|
      t.string :name, null: false
      t.string :quantity_to_store

      t.timestamps
    end
  end
end
