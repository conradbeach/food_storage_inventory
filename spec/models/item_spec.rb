require "rails_helper"

RSpec.describe Item do
  describe ".expiring_soon" do
    it "returns items expiring within 4 months, including expired items, soonest first" do
      travel_to Date.new(2026, 10, 10) do
        expired = create(:item, expires_on: Date.new(2026, 9, 1))
        at_boundary = create(:item, expires_on: Date.new(2027, 2, 10))
        soon = create(:item, expires_on: Date.new(2026, 12, 1))
        create(:item, expires_on: Date.new(2027, 2, 11))
        create(:item, expires_on: nil)

        expect(described_class.expiring_soon).to eq([expired, soon, at_boundary])
      end
    end
  end

  describe ".awaiting_expiration_notice" do
    it "returns expiring items that have not been notified about" do
      unnotified = create(:item, expires_on: 1.month.from_now)
      create(:item, expires_on: 1.month.from_now, expiration_notified_at: 1.day.ago)
      create(:item, expires_on: 1.year.from_now)

      expect(described_class.awaiting_expiration_notice).to eq([unnotified])
    end
  end

  describe "changing the expiration date" do
    it "clears the expiration notice so the new date is notified" do
      item = create(:item, expires_on: 1.month.from_now, expiration_notified_at: 1.day.ago)

      item.update!(expires_on: 2.months.from_now)

      expect(item.expiration_notified_at).to be_nil
    end
  end

  describe "changing other attributes" do
    it "keeps the expiration notice" do
      item = create(:item, expires_on: 1.month.from_now, expiration_notified_at: 1.day.ago)

      item.update!(amount: 10)

      expect(item.expiration_notified_at).to be_present
    end
  end

  describe "#name" do
    context "when the item has a description" do
      it "returns the description" do
        item = build(:item, description: "Hard Red")

        expect(item.name).to eq("Hard Red")
      end
    end

    context "when the item has no description" do
      it "returns the food's name" do
        item = build(:item, description: "", food: build(:food, name: "Pinto Beans"))

        expect(item.name).to eq("Pinto Beans")
      end
    end
  end

  describe "#expired?" do
    context "when the expiration date has passed" do
      it "returns true" do
        expect(build(:item, expires_on: Date.yesterday)).to be_expired
      end
    end

    context "when the expiration date is today or later" do
      it "returns false" do
        expect(build(:item, expires_on: Date.current)).to_not be_expired
      end
    end

    context "when the item does not expire" do
      it "returns false" do
        expect(build(:item, expires_on: nil)).to_not be_expired
      end
    end
  end

  describe "validation" do
    context "when the amount is negative" do
      it "is invalid" do
        item = build(:item, amount: -1)

        expect(item).to_not be_valid
        expect(item.errors[:amount]).to include("must be greater than or equal to 0")
      end
    end
  end
end
