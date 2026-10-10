require "rails_helper"

RSpec.describe "Admin categories" do
  before { sign_in }

  describe "GET /madmin/categories" do
    it "lists categories" do
      create(:category, name: "Grains")

      get madmin_categories_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Grains")
    end
  end

  describe "GET /madmin/categories/:id" do
    it "shows its foods in a table without a category column, alphabetically" do
      category = create(:category, name: "Grains")
      create(:food, category:, name: "Wheat")
      create(:food, category:, name: "Rice")

      get madmin_category_path(category)

      foods_table = response.parsed_body.css("table table")
      expect(foods_table.css("th").map { it.text.strip }).to_not include("Category")
      expect(foods_table.css("tbody tr").map { it.css("td").first.text.strip }).to eq(["Rice", "Wheat"])
    end
  end

  describe "GET /madmin/categories/new" do
    it "shows the form" do
      get new_madmin_category_path

      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /madmin/categories" do
    context "with valid attributes" do
      it "creates the record" do
        post madmin_categories_path, params: { category: attributes_for(:category, name: "Grains") }

        expect(Category.last.name).to eq("Grains")
        expect(response).to redirect_to(madmin_category_path(Category.last))
      end
    end

    context "without a name" do
      it "re-renders the form with errors" do
        post madmin_categories_path, params: { category: attributes_for(:category, name: "") }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("Name can&#39;t be blank")
      end
    end
  end

  describe "GET /madmin/categories/:id/edit" do
    it "shows the form" do
      get edit_madmin_category_path(create(:category))

      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /madmin/categories/:id" do
    it "updates the record" do
      record = create(:category)

      patch madmin_category_path(record), params: { category: { name: "Legumes" } }

      expect(record.reload.name.to_s).to eq("Legumes")
      expect(response).to redirect_to(madmin_category_path(record))
    end
  end

  describe "DELETE /madmin/categories/:id" do
    it "deletes the record" do
      record = create(:category)

      delete madmin_category_path(record)

      expect(Category).to_not exist(record.id)
      expect(response).to redirect_to(madmin_categories_path)
    end
  end
end
