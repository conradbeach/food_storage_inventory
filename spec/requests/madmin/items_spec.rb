require "rails_helper"

RSpec.describe "Admin items" do
  before { sign_in }

  describe "GET /madmin/items" do
    it "lists items with copy links" do
      create(:item, description: "Hard Red Wheat")

      get madmin_items_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Hard Red Wheat", "Copy and edit")
    end
  end

  describe "GET /madmin/items sort order" do
    it "lists the soonest expiring items first and items without a date last" do
      create(:item, description: "Salt", expires_on: nil)
      create(:item, description: "Wheat", expires_on: 10.years.from_now)
      create(:item, description: "Peanut Butter", expires_on: 1.month.from_now)

      get madmin_items_path

      expect(response.body.scan(/Salt|Wheat|Peanut Butter/).uniq).to eq(["Peanut Butter", "Wheat", "Salt"])
    end

    context "when sorted by latest expiration" do
      it "still lists items without a date last" do
        create(:item, description: "Salt", expires_on: nil)
        create(:item, description: "Wheat", expires_on: 10.years.from_now)
        create(:item, description: "Peanut Butter", expires_on: 1.month.from_now)

        get madmin_items_path(sort: "expires_on", direction: "desc")

        expect(response.body.scan(/Salt|Wheat|Peanut Butter/).uniq).to eq(["Wheat", "Peanut Butter", "Salt"])
      end
    end
  end

  describe "GET /madmin/items?scope=expiring_soon" do
    it "lists only items expiring soon" do
      create(:item, description: "Peanut Butter", expires_on: 1.month.from_now)
      create(:item, description: "Hard Red Wheat", expires_on: 10.years.from_now)

      get madmin_items_path(scope: "expiring_soon")

      expect(response.body).to include("Peanut Butter")
      expect(response.body).to_not include("Hard Red Wheat")
    end
  end

  describe "GET /madmin/items/:id" do
    it "shows the item with a readable expiration date" do
      item = create(:item, description: "Hard Red Wheat", expires_on: Date.new(2046, 1, 1))

      get madmin_item_path(item)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Hard Red Wheat", "January 1, 2046")
    end
  end

  describe "GET /madmin/items/new" do
    it "shows a form with a save and add another button" do
      get new_madmin_item_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Save and add another")
    end
  end

  describe "POST /madmin/items" do
    context "when saving" do
      it "creates the item and shows it" do
        food = create(:food)

        post madmin_items_path, params: { item: { food_id: food.id, description: "Rolled Oats", amount: "16.8" } }

        item = Item.last
        expect(item).to have_attributes(food:, description: "Rolled Oats", amount: 16.8)
        expect(response).to redirect_to(madmin_item_path(item))
      end
    end

    context "when saving and adding another" do
      it "creates the item and opens a new form prefilled with its details" do
        food = create(:food)
        attributes = { food_id: food.id, description: "Rolled Oats", amount: "16.8", expires_on: "2054-01-01" }

        post madmin_items_path, params: { item: attributes, add_another: "Save and add another" }
        follow_redirect!

        expect(Item.count).to eq(1)
        expect(response.body).to include("Rolled Oats was added.")
        expect(response.body).to include('value="Rolled Oats"', 'value="16.8"', 'value="2054-01-01"')
      end
    end

    context "when the item is invalid" do
      it "re-renders the form with errors" do
        food = create(:food)

        post madmin_items_path,
          params: { item: { food_id: food.id, amount: "-1" }, add_another: "Save and add another" }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("Amount must be greater than or equal to 0")
        expect(Item.count).to eq(0)
      end
    end
  end

  describe "copying an item" do
    it "opens a new item form prefilled from the item" do
      item = create(:item, description: "Hard Red Wheat", amount: 45, expires_on: Date.new(2040, 1, 1))
      get madmin_item_path(item)
      copy_link = response.parsed_body.css("a").find { it.text == "Copy and edit" }

      get copy_link["href"]

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(%(action="#{madmin_items_path}"))
      expect(response.body).to include('value="Hard Red Wheat"', 'value="45.0"', 'value="2040-01-01"')
    end
  end

  describe "GET /madmin/items/:id/edit" do
    it "shows the edit form without a save and add another button" do
      item = create(:item)

      get edit_madmin_item_path(item)

      expect(response).to have_http_status(:ok)
      expect(response.body).to_not include("Save and add another")
    end
  end

  describe "PATCH /madmin/items/:id" do
    it "updates the item" do
      item = create(:item, amount: 45)

      patch madmin_item_path(item), params: { item: { amount: "30" } }

      expect(item.reload.amount).to eq(30)
      expect(response).to redirect_to(madmin_item_path(item))
    end
  end

  describe "DELETE /madmin/items/:id" do
    it "deletes the item" do
      item = create(:item)

      delete madmin_item_path(item)

      expect(Item).to_not exist(item.id)
      expect(response).to redirect_to(madmin_items_path)
    end
  end
end
