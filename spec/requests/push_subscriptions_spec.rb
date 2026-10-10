require "rails_helper"

RSpec.describe "Push subscriptions" do
  describe "POST /push_subscription" do
    let(:subscription_params) do
      { endpoint: "https://push.example.com/abc", keys: { p256dh: "p256dh-key", auth: "auth-key" } }
    end

    context "when signed in" do
      it "saves the subscription for the current user" do
        user = sign_in

        post push_subscription_path, params: subscription_params, as: :json

        expect(response).to have_http_status(:created)
        expect(user.push_subscriptions.sole)
          .to have_attributes(endpoint: "https://push.example.com/abc", p256dh_key: "p256dh-key", auth_key: "auth-key")
      end
    end

    context "when the device is already subscribed" do
      it "updates the existing subscription" do
        existing = create(:push_subscription, endpoint: "https://push.example.com/abc", auth_key: "old-key")
        user = sign_in

        post push_subscription_path, params: subscription_params, as: :json

        expect(PushSubscription.sole).to have_attributes(id: existing.id, user:, auth_key: "auth-key")
      end
    end

    context "when signed out" do
      it "does not save the subscription" do
        post push_subscription_path, params: subscription_params, as: :json

        expect(PushSubscription.count).to eq(0)
      end
    end
  end

  describe "DELETE /push_subscription" do
    it "removes the current user's subscription for the endpoint" do
      user = sign_in
      create(:push_subscription, user:, endpoint: "https://push.example.com/abc")

      delete push_subscription_path, params: { endpoint: "https://push.example.com/abc" }, as: :json

      expect(response).to have_http_status(:no_content)
      expect(PushSubscription.count).to eq(0)
    end

    it "leaves other users' subscriptions alone" do
      sign_in
      create(:push_subscription, endpoint: "https://push.example.com/abc")

      delete push_subscription_path, params: { endpoint: "https://push.example.com/abc" }, as: :json

      expect(PushSubscription.count).to eq(1)
    end
  end
end
