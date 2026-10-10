class Item < ApplicationRecord
  EXPIRATION_WARNING_PERIOD = 4.months

  belongs_to :food

  validates :amount, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  before_update :reset_expiration_notice, if: :will_save_change_to_expires_on?

  scope :expiring_soon, -> { where(expires_on: ..(Date.current + EXPIRATION_WARNING_PERIOD)).order(:expires_on) }
  scope :awaiting_expiration_notice, -> { expiring_soon.where(expiration_notified_at: nil) }

  # Notifies every device about items newly expiring soon. Items stay
  # unnotified, to be retried, unless at least one device was reached.
  def self.send_expiration_notices
    items = awaiting_expiration_notice.includes(:food).to_a
    return if items.empty?

    delivered = PushSubscription.deliver_to_all(
      title: "Food storage expiring soon", body: expiration_notice_message(items), path: "/",
    )
    items.each { it.update!(expiration_notified_at: Time.current) } if delivered
  end

  def self.expiration_notice_message(items)
    if items.one?
      "#{items.first.name} expires #{items.first.expires_on.to_fs(:long)}."
    else
      "#{items.size} items expire within the next 4 months."
    end
  end
  private_class_method :expiration_notice_message

  def name
    description.presence || food.name
  end

  # Attributes for prefilling a new item that's like this one.
  def copyable_attributes
    slice(:food_id, :description, :amount, :expires_on)
  end

  def expired?
    expires_on.present? && expires_on < Date.current
  end

  private

  def reset_expiration_notice
    self.expiration_notified_at = nil
  end
end
