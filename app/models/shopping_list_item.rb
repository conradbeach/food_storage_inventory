class ShoppingListItem < ApplicationRecord
  validates :name, presence: true
end
