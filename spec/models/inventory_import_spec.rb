require "rails_helper"

RSpec.describe InventoryImport do
  let(:directory) { file_fixture("inventory_export") }

  describe "#run" do
    it "creates foods with their category, yearly target, and package details" do
      described_class.new(directory).run

      wheat = Food.find_by!(name: "Wheat")
      expect(wheat)
        .to have_attributes(unit: "lbs", yearly_amount_per_person: 132, package_amount: 5.5, package_price: 6.88)
      expect(wheat.category.name).to eq("Grains")
      expect(Food.find_by!(name: "Salt")).to have_attributes(yearly_amount_per_person: nil, package_amount: nil)
    end

    it "imports items with amounts and conservative expiration dates" do
      described_class.new(directory).run

      expect(Food.find_by!(name: "Wheat").items.reorder(:id).pluck(:description, :amount, :expires_on)).to eq(
        [
          ["Hard Red", 45, Date.new(2039, 1, 1)],
          ["Hard White", 1045, Date.new(2027, 8, 1)],
        ],
      )
      expect(Food.find_by!(name: "Salt").items.pluck(:expires_on)).to eq([nil, nil])
    end

    it "names items from their sub-table when combining several into one food" do
      described_class.new(directory).run

      expect(Food.find_by!(name: "Legumes").items.reorder(:id).pluck(:description))
        .to eq(["Black Beans", "White Beans", "White Beans: Great Northern Beans"])
    end

    it "handles foods measured in other units" do
      described_class.new(directory).run

      vitamin_c = Food.find_by!(name: "Vitamin C")
      expect(vitamin_c).to have_attributes(unit: "mg", yearly_amount_per_person: 32_850, total_amount: 45_000)
      long_term_food = Food.find_by!(name: "Long Term Food")
      expect(long_term_food).to have_attributes(unit: "calories", yearly_amount_per_person: 730_000)
      expect(long_term_food.items.sole).to have_attributes(description: "4-Week Emergency Food Supply", amount: 56_060)
    end

    it "keeps non-numeric amounts in the item description" do
      described_class.new(directory).run

      expect(Food.find_by!(name: "Garden Seeds").items.sole)
        .to have_attributes(description: "Seed Vault (195 grams, 20 varieties)", amount: nil)
    end

    it "imports people and household supplies, skipping totals and notes" do
      described_class.new(directory).run

      expect(Person.pluck(:name, :calories_per_day)).to contain_exactly(["Parent", 2000], ["Child", 1400])
      expect(HouseholdSupply.pluck(:name, :quantity_to_store)).to eq([["Bar Soap", "12 bars"]])
    end

    context "when items already exist" do
      it "refuses to import again" do
        create(:item)

        expect { described_class.new(directory).run }.to raise_error(described_class::AlreadyImportedError)
        expect(Person.count).to eq(0)
      end
    end
  end
end
