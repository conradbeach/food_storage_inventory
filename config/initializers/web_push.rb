Rails.application.config.x.vapid = {
  subject: ENV.fetch("VAPID_SUBJECT", nil),
  public_key: ENV.fetch("VAPID_PUBLIC_KEY", nil),
  private_key: ENV.fetch("VAPID_PRIVATE_KEY", nil),
}
