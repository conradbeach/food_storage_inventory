require "rails_helper"

RSpec.describe "Admin users" do
  let!(:current_user) { sign_in }

  describe "GET /madmin/users" do
    it "lists users without exposing password digests" do
      get madmin_users_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(current_user.email_address)
      expect(response.body).to_not include(current_user.password_digest)
    end
  end

  describe "GET /madmin/users/:id" do
    it "shows the user" do
      get madmin_user_path(current_user)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(current_user.email_address)
    end
  end

  describe "GET /madmin/users/new" do
    it "shows the form" do
      get new_madmin_user_path

      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /madmin/users" do
    context "with matching passwords" do
      it "creates a user who can sign in" do
        post madmin_users_path, params: {
          user: { email_address: "spouse@example.com", password: "secret123", password_confirmation: "secret123" },
        }

        expect(User.authenticate_by(email_address: "spouse@example.com", password: "secret123")).to be_present
      end
    end

    context "with mismatched passwords" do
      it "re-renders the form with errors" do
        post madmin_users_path, params: {
          user: { email_address: "spouse@example.com", password: "secret123", password_confirmation: "other" },
        }

        expect(response).to have_http_status(:unprocessable_content)
        expect(User.find_by(email_address: "spouse@example.com")).to be_nil
      end
    end
  end

  describe "GET /madmin/users/:id/edit" do
    it "shows the form" do
      get edit_madmin_user_path(current_user)

      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /madmin/users/:id" do
    it "resets the user's password" do
      user = create(:user)

      patch madmin_user_path(user),
        params: { user: { password: "new-password", password_confirmation: "new-password" } }

      expect(user.reload.authenticate("new-password")).to be_truthy
    end
  end

  describe "DELETE /madmin/users/:id" do
    it "deletes the user" do
      user = create(:user)

      delete madmin_user_path(user)

      expect(User).to_not exist(user.id)
    end
  end
end
