import { Controller } from "@hotwired/stimulus"

// Lets the user drag page thumbnails to reorder them (used by the Organize
// PDF tool). Unlike dropzone_controller's file-chip reordering, this moves
// the actual DOM nodes and reads the resulting order straight off them,
// since there's no underlying file list to keep in sync here.
export default class extends Controller {
  static targets = ["grid", "orderInput"]

  dragStart(event) {
    this.draggingElement = event.currentTarget
    event.dataTransfer.setData("text/plain", event.currentTarget.dataset.page)
  }

  dragOver(event) {
    event.preventDefault()
  }

  drop(event) {
    event.preventDefault()
    const target = event.currentTarget
    if (!this.draggingElement || this.draggingElement === target) return

    const items = Array.from(this.gridTarget.children)
    const fromIndex = items.indexOf(this.draggingElement)
    const toIndex = items.indexOf(target)

    if (fromIndex < toIndex) {
      target.after(this.draggingElement)
    } else {
      target.before(this.draggingElement)
    }

    this.syncOrder()
  }

  syncOrder() {
    const order = Array.from(this.gridTarget.children).map((item) => item.dataset.page)
    this.orderInputTarget.value = order.join(",")
  }
}
