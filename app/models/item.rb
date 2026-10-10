class Item < ApplicationRecord
  EXPIRATION_WARNING_PERIOD = 4.months

  belongs_to :food

  validates :amount, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  before_update :reset_expiration_notice, if: :will_save_change_to_expires_on?

  scope :expiring_soon, -> { where(expires_on: ..(Date.current + EXPIRATION_WARNING_PERIOD)).order(:expires_on) }
  scope :awaiting_expiration_notice, -> { expiring_soon.where(expiration_notified_at: nil) }

  def name
    description.presence || food.name
  end

  def expired?
    expires_on.present? && expires_on < Date.current
  end

  private

  def reset_expiration_notice
    self.expiration_notified_at = nil
  end
end
