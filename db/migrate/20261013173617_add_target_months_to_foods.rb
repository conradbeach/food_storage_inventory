class AddTargetMonthsToFoods < ActiveRecord::Migration[8.1]
  def change
    add_column :foods, :target_months, :integer, default: 12, null: false
  end
end
