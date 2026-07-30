import { Controller } from "@hotwired/stimulus"

// Lets the user add/remove page-range input rows (used by the Split PDF form).
export default class extends Controller {
  static targets = ["template", "container"]

  add() {
    const content = this.templateTarget.content.cloneNode(true)
    this.containerTarget.appendChild(content)
  }

  remove(event) {
    const rows = this.containerTarget.querySelectorAll(".range-row")
    const row = event.target.closest(".range-row")

    if (rows.length > 1) {
      row.remove()
    } else {
      row.querySelector("input").value = ""
    }
  }
}
