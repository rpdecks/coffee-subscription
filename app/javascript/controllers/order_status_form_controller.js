import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["status", "tracking"]

  connect() {
    this.toggleTracking()
  }

  toggleTracking() {
    if (!this.hasTrackingTarget) return

    const showTracking = this.statusTarget.value === "shipped"

    this.trackingTarget.classList.toggle("hidden", !showTracking)

    const trackingInput = this.trackingTarget.querySelector("input")
    if (trackingInput) {
      trackingInput.disabled = !showTracking
    }
  }
}
