class ShoppingListItemResource < Madmin::Resource
  attribute :id, form: false, index: false
  attribute :name
  attribute :notes, index: true
  attribute :created_at, form: false, index: false
  attribute :updated_at, form: false, index: false

  def self.display_name(record) = record.name
end
