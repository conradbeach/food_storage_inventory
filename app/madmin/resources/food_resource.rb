class FoodResource < Madmin::Resource
  menu position: 2

  attribute :id, form: false, index: false
  attribute :name
  attribute :category, index: true
  attribute :unit, index: true
  attribute :yearly_amount_per_person, index: true, description: "Leave blank if this food has no supply target."
  attribute :target_months, index: true, description: "How many months of this food to keep on hand."
  attribute :package_amount, description: "Amount in one purchasable package, for the shopping list."
  attribute :package_price
  attribute :created_at, form: false, index: false
  attribute :updated_at, form: false, index: false
  attribute :items, form: false

  def self.display_name(record) = record.name

  def self.default_sort_column = "name"

  def self.default_sort_direction = "asc"
end
