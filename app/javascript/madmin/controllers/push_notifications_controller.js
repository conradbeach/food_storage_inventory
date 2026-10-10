import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["unsupported", "denied", "disabled", "enabled"]
  static values = { vapidPublicKey: String, url: String }

  async connect() {
    if (!("serviceWorker" in navigator) || !("PushManager" in window)) return this.show("unsupported")
    if (Notification.permission === "denied") return this.show("denied")

    const subscription = await this.currentSubscription()
    this.show(subscription ? "enabled" : "disabled")
  }

  async enable() {
    if (await Notification.requestPermission() !== "granted") return this.show("denied")

    const registration = await navigator.serviceWorker.register("/service-worker")
    await navigator.serviceWorker.ready
    const subscription = await registration.pushManager.subscribe({
      userVisibleOnly: true,
      applicationServerKey: this.decodedVapidPublicKey
    })

    await this.request("POST", subscription.toJSON())
    this.show("enabled")
  }

  async disable() {
    const subscription = await this.currentSubscription()
    if (subscription) {
      await this.request("DELETE", { endpoint: subscription.endpoint })
      await subscription.unsubscribe()
    }
    this.show("disabled")
  }

  async currentSubscription() {
    const registration = await navigator.serviceWorker.getRegistration()
    return registration?.pushManager.getSubscription()
  }

  request(method, body) {
    return fetch(this.urlValue, {
      method,
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector("meta[name=csrf-token]").content
      },
      body: JSON.stringify(body)
    })
  }

  show(state) {
    for (const name of this.constructor.targets) {
      this[`${name}Target`].hidden = name !== state
    }
  }

  get decodedVapidPublicKey() {
    const base64 = this.vapidPublicKeyValue.replace(/-/g, "+").replace(/_/g, "/")
    return Uint8Array.from(atob(base64), (char) => char.charCodeAt(0))
  }
}
