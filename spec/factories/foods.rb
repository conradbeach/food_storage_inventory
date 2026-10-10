FactoryBot.define do
  factory :food do
    category
    sequence(:name) { |n| "Food #{n}" }
    unit { "lbs" }
  end
end
