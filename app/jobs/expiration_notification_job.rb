class ExpirationNotificationJob < ApplicationJob
  def perform
    items = Item.awaiting_expiration_notice.includes(:food).to_a
    return if items.empty?

    delivered = PushSubscription.find_each.map do |subscription|
      subscription.deliver(title: "Food storage expiring soon", body: message_for(items), path: "/")
    end

    items.each { it.update!(expiration_notified_at: Time.current) } if delivered.any?
  end

  private

  def message_for(items)
    if items.one?
      "#{items.first.name} expires #{items.first.expires_on.to_fs(:long)}."
    else
      "#{items.size} items expire within the next 4 months."
    end
  end
end
