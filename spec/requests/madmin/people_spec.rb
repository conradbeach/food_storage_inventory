require "rails_helper"

RSpec.describe "Admin people" do
  before { sign_in }

  describe "GET /madmin/people" do
    it "lists people" do
      create(:person, name: "Jordan")

      get madmin_people_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Jordan")
    end
  end

  describe "GET /madmin/people/:id" do
    it "shows the record" do
      record = create(:person, name: "Jordan")

      get madmin_person_path(record)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Jordan")
    end
  end

  describe "GET /madmin/people/new" do
    it "shows the form" do
      get new_madmin_person_path

      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /madmin/people" do
    context "with valid attributes" do
      it "creates the record" do
        post madmin_people_path, params: { person: attributes_for(:person, name: "Jordan") }

        expect(Person.last.name).to eq("Jordan")
        expect(response).to redirect_to(madmin_person_path(Person.last))
      end
    end

    context "without a name" do
      it "re-renders the form with errors" do
        post madmin_people_path, params: { person: attributes_for(:person, name: "") }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("Name can&#39;t be blank")
      end
    end
  end

  describe "GET /madmin/people/:id/edit" do
    it "shows the form" do
      get edit_madmin_person_path(create(:person))

      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /madmin/people/:id" do
    it "updates the record" do
      record = create(:person)

      patch madmin_person_path(record), params: { person: { calories_per_day: "1800" } }

      expect(record.reload.calories_per_day.to_s).to eq("1800")
      expect(response).to redirect_to(madmin_person_path(record))
    end
  end

  describe "DELETE /madmin/people/:id" do
    it "deletes the record" do
      record = create(:person)

      delete madmin_person_path(record)

      expect(Person).to_not exist(record.id)
      expect(response).to redirect_to(madmin_people_path)
    end
  end
end
