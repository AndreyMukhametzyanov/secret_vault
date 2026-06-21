import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "source", "button" ]
  static values = { copiedLabel: String }

  copy() {
    const textToCopy = this.sourceTarget.value

    navigator.clipboard.writeText(textToCopy).then(() => {
      const originalText = this.buttonTarget.innerText
      this.buttonTarget.innerText = this.copiedLabelValue
      this.buttonTarget.classList.replace("btn-primary", "btn-success")

      setTimeout(() => {
        this.buttonTarget.innerText = originalText
        this.buttonTarget.classList.replace("btn-success", "btn-primary")
      }, 2000)
    })
  }
}
