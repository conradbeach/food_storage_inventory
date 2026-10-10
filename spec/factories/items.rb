FactoryBot.define do
  factory :item do
    food
    description { "Hard White" }
    amount { 45 }
    expires_on { 10.years.from_now.to_date }
  end
end
