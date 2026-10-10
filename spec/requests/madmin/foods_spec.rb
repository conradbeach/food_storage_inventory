require "rails_helper"

RSpec.describe "Admin foods" do
  before { sign_in }

  describe "GET /madmin/foods" do
    it "lists foods" do
      create(:food, name: "Wheat")

      get madmin_foods_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Wheat")
    end
  end

  describe "GET /madmin/foods/:id" do
    it "shows its items in a table with the items index's columns and actions, except food" do
      food = create(:food, name: "Wheat")
      create(:item, food:, description: "Hard Red", amount: 45, expires_on: Date.new(2048, 1, 1))

      get madmin_food_path(food)

      items_table = response.parsed_body.css("table table")
      expect(items_table.css("th").map { it.text.strip }).to eq(["Description", "Amount", "Expires on", ""])
      expect(items_table.css("tbody td").map { it.text.squish })
        .to eq(["Hard Red", "45.0", "January 1, 2048", "View Edit Copy and edit"])
    end

    it "lists its items soonest expiring first, with undated items last" do
      food = create(:food)
      create(:item, food:, description: "Hard Red", expires_on: Date.new(2048, 1, 1))
      create(:item, food:, description: "Hard White", expires_on: nil)
      create(:item, food:, description: "Bread Flour", expires_on: Date.new(2030, 6, 1))

      get madmin_food_path(food)

      descriptions = response.parsed_body.css("table table tbody tr").map { it.css("td").first.text.strip }
      expect(descriptions).to eq(["Bread Flour", "Hard Red", "Hard White"])
    end
  end

  describe "GET /madmin/foods/new" do
    it "shows the form" do
      get new_madmin_food_path

      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /madmin/foods" do
    context "with valid attributes" do
      it "creates the food" do
        category = create(:category)

        post madmin_foods_path, params: {
          food: { name: "Rice", category_id: category.id, unit: "lbs", yearly_amount_per_person: "65" },
        }

        expect(Food.last).to have_attributes(name: "Rice", category:, yearly_amount_per_person: 65)
        expect(response).to redirect_to(madmin_food_path(Food.last))
      end
    end

    context "without a name" do
      it "re-renders the form with errors" do
        post madmin_foods_path, params: { food: { name: "", category_id: create(:category).id } }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("Name can&#39;t be blank")
      end
    end
  end

  describe "GET /madmin/foods/:id/edit" do
    it "shows the form" do
      get edit_madmin_food_path(create(:food))

      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /madmin/foods/:id" do
    it "updates the food" do
      food = create(:food)

      patch madmin_food_path(food), params: { food: { package_price: "7.67" } }

      expect(food.reload.package_price).to eq(7.67)
    end
  end

  describe "DELETE /madmin/foods/:id" do
    context "when the food has no items" do
      it "deletes the food" do
        food = create(:food)

        delete madmin_food_path(food)

        expect(Food).to_not exist(food.id)
      end
    end

    context "when the food has items" do
      it "keeps the food and explains why" do
        food = create(:food)
        create(:item, food:)

        delete madmin_food_path(food)

        expect(Food).to exist(food.id)
        expect(flash[:alert]).to eq("Cannot delete record because dependent items exist")
      end
    end
  end
end
