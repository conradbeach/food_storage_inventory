require "rails_helper"

RSpec.describe PushSubscription do
  describe "#deliver" do
    context "when the push service accepts the notification" do
      it "sends the notification payload and returns true" do
        subscription = create(:push_subscription)
        allow(WebPush).to receive(:payload_send)

        result = subscription.deliver(title: "Expiring", body: "Wheat expires soon", path: "/")

        expect(result).to be(true)
        message = { title: "Expiring", options: { body: "Wheat expires soon", data: { path: "/" } } }.to_json
        expect(WebPush).to have_received(:payload_send)
          .with(hash_including(endpoint: subscription.endpoint, p256dh: "p256dh-key", auth: "auth-key", message:))
      end
    end

    context "when the subscription has expired" do
      it "deletes the subscription and returns false" do
        subscription = create(:push_subscription)
        response = instance_double(Net::HTTPGone, body: "")
        allow(WebPush).to receive(:payload_send)
          .and_raise(WebPush::ExpiredSubscription.new(response, "push.example.com"))

        result = subscription.deliver(title: "Expiring", body: "Wheat expires soon", path: "/")

        expect(result).to be(false)
        expect(described_class).to_not exist(subscription.id)
      end
    end

    context "when the push service fails" do
      it "keeps the subscription and returns false" do
        subscription = create(:push_subscription)
        response = instance_double(Net::HTTPServiceUnavailable, body: "")
        allow(WebPush).to receive(:payload_send)
          .and_raise(WebPush::PushServiceError.new(response, "push.example.com"))

        result = subscription.deliver(title: "Expiring", body: "Wheat expires soon", path: "/")

        expect(result).to be(false)
        expect(described_class).to exist(subscription.id)
      end
    end
  end
end
