require "rails_helper"

RSpec.describe "Dashboard" do
  it "shows items expiring soon after signing in" do
    user = create(:user)
    create(:item, description: "Peanut Butter", expires_on: 2.months.from_now)
    create(:item, description: "Hard Red Wheat", expires_on: 10.years.from_now)

    visit root_path
    expect(page).to have_current_path(new_session_path)
    sign_in_as(user)

    within("#expiring-items") do
      expect(page).to have_link("Peanut Butter")
      expect(page).to have_no_content("Hard Red Wheat")
    end
  end
end
