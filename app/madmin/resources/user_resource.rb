class UserResource < Madmin::Resource
  attribute :id, form: false, index: false
  attribute :email_address, index: true
  attribute :password, index: false, show: false
  attribute :password_confirmation, index: false, show: false
  attribute :created_at, form: false
  attribute :updated_at, form: false, index: false

  def self.display_name(record) = record.email_address
end
