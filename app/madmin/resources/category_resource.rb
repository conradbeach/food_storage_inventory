class CategoryResource < Madmin::Resource
  menu position: 1

  attribute :id, form: false, index: false
  attribute :name
  attribute :created_at, form: false, index: false
  attribute :updated_at, form: false, index: false
  attribute :foods, form: false

  def self.display_name(record) = record.name

  def self.default_sort_column = "name"

  def self.default_sort_direction = "asc"
end
