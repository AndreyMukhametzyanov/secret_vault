import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "modal", "form" ]

  connect() {
    this.modal = bootstrap.Modal.getOrCreateInstance(this.modalTarget)
  }

  open(event) {
    event.preventDefault()
    this.modal.show()
  }

  confirm() {
    this.formTarget.requestSubmit()
    this.modal.hide()
  }
}
