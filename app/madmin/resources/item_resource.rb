class ItemResource < Madmin::Resource
  menu position: 3

  attribute :id, form: false, index: false
  attribute :food, index: true
  attribute :description, index: true
  attribute :amount, index: true
  attribute :expires_on, index: true
  attribute :expiration_notified_at, form: false, index: false
  attribute :created_at, form: false, index: false
  attribute :updated_at, form: false, index: false

  scope :expiring_soon

  member_action collection: true do |record|
    link_to "Copy and edit", new_madmin_item_path(item: record.copyable_attributes), class: "btn btn-secondary"
  end

  def self.display_name(record) = record.name

  def self.default_sort_column = "expires_on"

  def self.default_sort_direction = "asc"
end
