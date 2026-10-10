class Person < ApplicationRecord
  # Supply targets are per adult eating 2,000 calories a day.
  ADULT_DAILY_CALORIES = 2000

  validates :name, presence: true
  validates :calories_per_day, numericality: { only_integer: true, greater_than: 0 }

  def self.household_size
    sum(:calories_per_day).to_d / ADULT_DAILY_CALORIES
  end
end
