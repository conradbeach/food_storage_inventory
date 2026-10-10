class Category < ApplicationRecord
  has_many :foods, -> { order(:name) }, inverse_of: :category, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true
end
