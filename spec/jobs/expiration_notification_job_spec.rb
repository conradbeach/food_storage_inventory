require "rails_helper"

RSpec.describe ExpirationNotificationJob do
  context "when one new item is expiring soon" do
    it "notifies every subscription about the item and marks it notified" do
      item = create(:item, description: "Peanut Butter", expires_on: Date.new(2026, 12, 1))
      first, second = create_list(:push_subscription, 2)
      allow(WebPush).to receive(:payload_send)

      travel_to(Date.new(2026, 10, 10)) { described_class.perform_now }

      message = include("Peanut Butter expires December 1, 2026.").and(include('"path":"/madmin"'))
      expect(WebPush).to have_received(:payload_send).with(hash_including(endpoint: first.endpoint, message:))
      expect(WebPush).to have_received(:payload_send).with(hash_including(endpoint: second.endpoint, message:))
      expect(item.reload.expiration_notified_at).to be_present
    end
  end

  context "when several new items are expiring soon" do
    it "sends one notification summarizing the count" do
      create_list(:item, 3, expires_on: 1.month.from_now)
      allow(WebPush).to receive(:payload_send)
      create(:push_subscription)

      described_class.perform_now

      expect(WebPush).to have_received(:payload_send).once
        .with(hash_including(message: include("3 items expire within the next 4 months.")))
    end
  end

  context "when one subscription can't be reached but another accepts the notification" do
    it "still notifies the other subscription and marks the item notified" do
      item = create(:item, expires_on: 1.month.from_now)
      unreachable, reachable = create_list(:push_subscription, 2)
      allow(WebPush).to receive(:payload_send).with(hash_including(endpoint: unreachable.endpoint))
        .and_raise(Errno::ECONNREFUSED)
      allow(WebPush).to receive(:payload_send).with(hash_including(endpoint: reachable.endpoint))

      described_class.perform_now

      expect(WebPush).to have_received(:payload_send).with(hash_including(endpoint: reachable.endpoint))
      expect(item.reload.expiration_notified_at).to be_present
    end
  end

  context "when the expiring items were already notified" do
    it "sends nothing" do
      create(:item, expires_on: 1.month.from_now, expiration_notified_at: 1.week.ago)
      allow(WebPush).to receive(:payload_send)
      create(:push_subscription)

      described_class.perform_now

      expect(WebPush).to_not have_received(:payload_send)
    end
  end

  context "when no subscription accepts the notification" do
    it "leaves the items unnotified so they are retried tomorrow" do
      item = create(:item, expires_on: 1.month.from_now)
      response = instance_double(Net::HTTPServiceUnavailable, body: "")
      allow(WebPush).to receive(:payload_send)
        .and_raise(WebPush::PushServiceError.new(response, "push.example.com"))
      create(:push_subscription)

      described_class.perform_now

      expect(item.reload.expiration_notified_at).to be_nil
    end
  end

  context "when there are no subscriptions" do
    it "leaves the items unnotified" do
      item = create(:item, expires_on: 1.month.from_now)

      described_class.perform_now

      expect(item.reload.expiration_notified_at).to be_nil
    end
  end
end
