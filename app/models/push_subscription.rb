class PushSubscription < ApplicationRecord
  belongs_to :user

  validates :endpoint, :p256dh_key, :auth_key, presence: true
  validates :endpoint, uniqueness: true

  # Returns whether the push service accepted the notification.
  def deliver(title:, body:, path:)
    WebPush.payload_send(
      message: { title:, options: { body:, data: { path: } } }.to_json,
      endpoint:,
      p256dh: p256dh_key,
      auth: auth_key,
      vapid: Rails.configuration.x.vapid,
    )
    true
  rescue WebPush::ExpiredSubscription, WebPush::InvalidSubscription
    destroy
    false
  rescue WebPush::Error => e
    Rails.logger.error("Push to subscription #{id} failed: #{e.message}")
    false
  end
end
