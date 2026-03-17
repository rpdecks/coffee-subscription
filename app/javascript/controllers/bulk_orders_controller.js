import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["master", "row", "count", "submit"]

  connect() {
    this.refresh()
  }

  toggleAll() {
    this.rowTargets.forEach((checkbox) => {
      checkbox.checked = this.masterTarget.checked
    })

    this.refresh()
  }

  refresh() {
    const selectedCount = this.rowTargets.filter((checkbox) => checkbox.checked).length
    const allSelected = this.rowTargets.length > 0 && selectedCount === this.rowTargets.length

    if (this.hasMasterTarget) {
      this.masterTarget.checked = allSelected
      this.masterTarget.indeterminate = selectedCount > 0 && !allSelected
    }

    if (this.hasCountTarget) {
      this.countTarget.textContent = selectedCount
    }

    if (this.hasSubmitTarget) {
      this.submitTarget.disabled = selectedCount === 0
    }
  }
}
