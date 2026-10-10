require "rails_helper"

RSpec.describe "Admin shopping list items" do
  before { sign_in }

  describe "GET /madmin/shopping_list_items" do
    it "lists shopping list items" do
      create(:shopping_list_item, name: "Propane")

      get madmin_shopping_list_items_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Propane")
    end
  end

  describe "GET /madmin/shopping_list_items/:id" do
    it "shows the record" do
      record = create(:shopping_list_item, name: "Propane")

      get madmin_shopping_list_item_path(record)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Propane")
    end
  end

  describe "GET /madmin/shopping_list_items/new" do
    it "shows the form" do
      get new_madmin_shopping_list_item_path

      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /madmin/shopping_list_items" do
    context "with valid attributes" do
      it "creates the record" do
        post madmin_shopping_list_items_path,
          params: { shopping_list_item: attributes_for(:shopping_list_item, name: "Propane") }

        expect(ShoppingListItem.last.name).to eq("Propane")
        expect(response).to redirect_to(madmin_shopping_list_item_path(ShoppingListItem.last))
      end
    end

    context "without a name" do
      it "re-renders the form with errors" do
        params = { shopping_list_item: attributes_for(:shopping_list_item, name: "") }

        post(madmin_shopping_list_items_path, params:)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("Name can&#39;t be blank")
      end
    end
  end

  describe "GET /madmin/shopping_list_items/:id/edit" do
    it "shows the form" do
      get edit_madmin_shopping_list_item_path(create(:shopping_list_item))

      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /madmin/shopping_list_items/:id" do
    it "updates the record" do
      record = create(:shopping_list_item)

      patch madmin_shopping_list_item_path(record), params: { shopping_list_item: { notes: "One 100 lb tank" } }

      expect(record.reload.notes).to eq("One 100 lb tank")
      expect(response).to redirect_to(madmin_shopping_list_item_path(record))
    end
  end

  describe "DELETE /madmin/shopping_list_items/:id" do
    it "deletes the record" do
      record = create(:shopping_list_item)

      delete madmin_shopping_list_item_path(record)

      expect(ShoppingListItem).to_not exist(record.id)
      expect(response).to redirect_to(madmin_shopping_list_items_path)
    end
  end
end
