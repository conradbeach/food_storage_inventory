require "rails_helper"

RSpec.describe Person do
  describe ".household_size" do
    it "counts each person as a fraction of a 2,000 calorie adult" do
      create(:person, calories_per_day: 2000)
      create(:person, calories_per_day: 1800)
      create(:person, calories_per_day: 1400)

      expect(described_class.household_size).to eq(2.6)
    end

    context "when there are no people" do
      it "returns zero" do
        expect(described_class.household_size).to eq(0)
      end
    end
  end
end
