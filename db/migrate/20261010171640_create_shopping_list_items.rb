class CreateShoppingListItems < ActiveRecord::Migration[8.1]
  def change
    create_table :shopping_list_items do |t|
      t.string :name, null: false
      t.string :notes

      t.timestamps
    end
  end
end
