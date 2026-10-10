class ExpirationNotificationJob < ApplicationJob
  def perform
    Item.send_expiration_notices
  end
end
