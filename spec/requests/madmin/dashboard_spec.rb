require "rails_helper"

RSpec.describe "Admin dashboard" do
  before { sign_in }

  describe "GET /madmin" do
    it "lists items expiring within 4 months, including expired ones" do
      create(:item, description: "Expired Peanut Butter", expires_on: 1.week.ago)
      create(:item, description: "Sunflower Oil", expires_on: 3.months.from_now)
      create(:item, description: "Hard Red Wheat", expires_on: 10.years.from_now)

      get madmin_root_path

      expiring_section = response.body[%r{<section id="expiring-items">.*?</section>}m]
      expect(expiring_section).to include("Expired Peanut Butter", "(expired)", "Sunflower Oil")
      expect(expiring_section).to_not include("Hard Red Wheat")
    end

    it "summarizes supply for each food based on the household size" do
      create(:person, calories_per_day: 2000)
      create(:person, calories_per_day: 2000)
      food = create(:food, name: "Butter", yearly_amount_per_person: 6, package_amount: 2, package_price: 8.58)
      create(:item, food:, amount: 3)

      get madmin_root_path

      summary_section = response.body[%r{<section id="supply-summary">.*?</section>}m]
      expect(summary_section).to include("Household size: 2 adults")
      expect(summary_section).to include("<td>3 lbs</td>", "<td>0.25</td>", "<td>9</td>", "<td>5</td>", "$42.90")
    end

    context "when nothing is expiring soon" do
      it "says so" do
        create(:item, expires_on: 10.years.from_now)

        get madmin_root_path

        expect(response.body).to include("Nothing expires in the next 4 months.")
      end
    end

    context "when push notifications are configured" do
      it "offers to enable notifications" do
        allow(Rails.application.credentials).to receive(:dig).and_call_original
        allow(Rails.application.credentials).to receive(:dig).with(:vapid, :public_key).and_return("public-key")

        get madmin_root_path

        expect(response.body).to include('data-push-notifications-vapid-public-key-value="public-key"')
      end
    end

    context "when push notifications are not configured" do
      it "does not offer notifications" do
        allow(Rails.application.credentials).to receive(:dig).and_call_original
        allow(Rails.application.credentials).to receive(:dig).with(:vapid, :public_key).and_return(nil)

        get madmin_root_path

        expect(response.body).to_not include("push-notifications")
      end
    end
  end
end
