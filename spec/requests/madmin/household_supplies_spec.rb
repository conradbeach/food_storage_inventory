require "rails_helper"

RSpec.describe "Admin household supplies" do
  before { sign_in }

  describe "GET /madmin/household_supplies" do
    it "lists household supplies" do
      create(:household_supply, name: "Bar Soap")

      get madmin_household_supplies_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Bar Soap")
    end
  end

  describe "GET /madmin/household_supplies/:id" do
    it "shows the record" do
      record = create(:household_supply, name: "Bar Soap")

      get madmin_household_supply_path(record)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Bar Soap")
    end
  end

  describe "GET /madmin/household_supplies/new" do
    it "shows the form" do
      get new_madmin_household_supply_path

      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /madmin/household_supplies" do
    context "with valid attributes" do
      it "creates the record" do
        post madmin_household_supplies_path,
          params: { household_supply: attributes_for(:household_supply, name: "Bar Soap") }

        expect(HouseholdSupply.last.name).to eq("Bar Soap")
        expect(response).to redirect_to(madmin_household_supply_path(HouseholdSupply.last))
      end
    end

    context "without a name" do
      it "re-renders the form with errors" do
        post madmin_household_supplies_path, params: { household_supply: attributes_for(:household_supply, name: "") }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("Name can&#39;t be blank")
      end
    end
  end

  describe "GET /madmin/household_supplies/:id/edit" do
    it "shows the form" do
      get edit_madmin_household_supply_path(create(:household_supply))

      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /madmin/household_supplies/:id" do
    it "updates the record" do
      record = create(:household_supply)

      patch madmin_household_supply_path(record), params: { household_supply: { quantity_to_store: "24 bars" } }

      expect(record.reload.quantity_to_store.to_s).to eq("24 bars")
      expect(response).to redirect_to(madmin_household_supply_path(record))
    end
  end

  describe "DELETE /madmin/household_supplies/:id" do
    it "deletes the record" do
      record = create(:household_supply)

      delete madmin_household_supply_path(record)

      expect(HouseholdSupply).to_not exist(record.id)
      expect(response).to redirect_to(madmin_household_supplies_path)
    end
  end
end
