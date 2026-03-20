import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["status", "tracking", "deliveryNote", "nextStep"]

  connect() {
    this.syncFormState()
  }

  toggleTracking() {
    this.syncFormState()
  }

  syncFormState() {
    const selectedStatus = this.statusTarget.value

    if (this.hasTrackingTarget) {
      const showTracking = selectedStatus === "shipped"

      this.trackingTarget.classList.toggle("hidden", !showTracking)

      const trackingInput = this.trackingTarget.querySelector("input")
      if (trackingInput) {
        trackingInput.disabled = !showTracking
      }
    }

    if (this.hasDeliveryNoteTarget) {
      const showDeliveryNote = selectedStatus === "delivered" && !this.hasExistingTracking()

      this.deliveryNoteTarget.classList.toggle("hidden", !showDeliveryNote)

      const deliveryNoteInput = this.deliveryNoteTarget.querySelector("textarea")
      if (deliveryNoteInput) {
        deliveryNoteInput.disabled = !showDeliveryNote
        deliveryNoteInput.required = showDeliveryNote
      }
    }

    if (this.hasNextStepTarget) {
      this.nextStepTarget.textContent = this.nextStepFor(selectedStatus)
    }
  }

  nextStepFor(status) {
    return this.nextSteps()[status] || "Review order"
  }

  nextSteps() {
    try {
      return JSON.parse(this.statusTarget.dataset.nextSteps || "{}")
    } catch {
      return {}
    }
  }

  hasExistingTracking() {
    return this.statusTarget.dataset.hasTracking === "true"
  }
}
