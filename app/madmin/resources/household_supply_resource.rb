class HouseholdSupplyResource < Madmin::Resource
  attribute :id, form: false, index: false
  attribute :name
  attribute :quantity_to_store, index: true
  attribute :created_at, form: false, index: false
  attribute :updated_at, form: false, index: false

  def self.display_name(record) = record.name

  def self.default_sort_column = "name"

  def self.default_sort_direction = "asc"
end
