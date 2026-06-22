import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "input", "toggle" ]
  static values = { showLabel: String, hideLabel: String }

  toggle() {
    const input = this.inputTarget
    const revealing = input.type === "password"

    input.type = revealing ? "text" : "password"

    if (this.hasToggleTarget) {
      this.toggleTarget.textContent = revealing ? this.hideLabelValue : this.showLabelValue
      this.toggleTarget.setAttribute("aria-pressed", revealing ? "true" : "false")
    }
  }
}
