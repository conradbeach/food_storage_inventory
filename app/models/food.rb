class Food < ApplicationRecord
  belongs_to :category
  has_many :items, -> { by_expiration }, inverse_of: :food, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true
  validates :unit, presence: true
  validates :yearly_amount_per_person, :package_amount, numericality: { greater_than: 0 }, allow_nil: true
  validates :package_price, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :target_months, numericality: { only_integer: true, greater_than: 0 }

  def total_amount
    items.sum { it.amount || 0 }
  end

  # The amount the household needs on hand to cover the food's target months.
  def target_amount(household_size)
    return if yearly_amount_per_person.nil?

    yearly_amount_per_person * household_size * target_months / 12
  end

  def percent_of_target(household_size)
    target = target_amount(household_size)
    return if target.nil? || target.zero?

    total_amount / target * 100
  end

  def below_target?(household_size)
    percent = percent_of_target(household_size)
    percent.present? && percent < 100
  end

  def amount_needed(household_size)
    target = target_amount(household_size)
    return if target.nil?

    [target - total_amount, 0].max
  end

  def packages_needed(household_size)
    needed = amount_needed(household_size)
    return if needed.nil? || package_amount.nil?

    (needed / package_amount).ceil
  end

  def estimated_cost(household_size)
    packages = packages_needed(household_size)
    return if packages.nil? || package_price.nil?

    packages * package_price
  end
end
