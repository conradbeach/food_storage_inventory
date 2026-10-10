require "rails_helper"

RSpec.describe Food do
  describe "#total_amount" do
    it "sums the amounts of the food's items" do
      food = create(:food)
      create(:item, food:, amount: 45)
      create(:item, food:, amount: 5.5)
      create(:item, food:, amount: nil)

      expect(food.total_amount).to eq(50.5)
    end
  end

  describe "#years_supplied" do
    context "when the food has a yearly target" do
      it "divides the total amount by the household's yearly need" do
        food = create(:food, yearly_amount_per_person: 132)
        create(:item, food:, amount: 834)

        expect(food.years_supplied(5.1).round(2)).to eq(1.24)
      end
    end

    context "when the food has no yearly target" do
      it "returns nil" do
        food = create(:food, yearly_amount_per_person: nil)

        expect(food.years_supplied(5.1)).to be_nil
      end
    end

    context "when the household is empty" do
      it "returns nil" do
        food = create(:food, yearly_amount_per_person: 132)

        expect(food.years_supplied(0)).to be_nil
      end
    end
  end

  describe "#amount_needed" do
    context "when the household's yearly need exceeds the total amount" do
      it "returns the shortfall" do
        food = create(:food, yearly_amount_per_person: 6)
        create(:item, food:, amount: 19.43)

        expect(food.amount_needed(5.1)).to eq(11.17)
      end
    end

    context "when the total amount covers the household's yearly need" do
      it "returns zero" do
        food = create(:food, yearly_amount_per_person: 132)
        create(:item, food:, amount: 834)

        expect(food.amount_needed(5.1)).to eq(0)
      end
    end

    context "when the food has no yearly target" do
      it "returns nil" do
        food = create(:food, yearly_amount_per_person: nil)

        expect(food.amount_needed(5.1)).to be_nil
      end
    end
  end

  describe "#packages_needed" do
    context "when the food has a package amount" do
      it "rounds the number of packages up" do
        food = create(:food, yearly_amount_per_person: 6, package_amount: 2)
        create(:item, food:, amount: 19.43)

        expect(food.packages_needed(5.1)).to eq(6)
      end
    end

    context "when the food has no package amount" do
      it "returns nil" do
        food = create(:food, yearly_amount_per_person: 6, package_amount: nil)

        expect(food.packages_needed(5.1)).to be_nil
      end
    end
  end

  describe "#estimated_cost" do
    context "when the food has a package amount and price" do
      it "multiplies the packages needed by the package price" do
        food = create(:food, yearly_amount_per_person: 6, package_amount: 2, package_price: 8.58)
        create(:item, food:, amount: 19.43)

        expect(food.estimated_cost(5.1)).to eq(51.48)
      end
    end

    context "when the food has no package price" do
      it "returns nil" do
        food = create(:food, yearly_amount_per_person: 6, package_amount: 2, package_price: nil)

        expect(food.estimated_cost(5.1)).to be_nil
      end
    end
  end

  describe "deletion" do
    context "when the food has items" do
      it "is prevented" do
        food = create(:food)
        create(:item, food:)

        expect(food.destroy).to be(false)
        expect(food.errors[:base]).to include("Cannot delete record because dependent items exist")
      end
    end
  end
end
