import { Controller } from "@hotwired/stimulus"

// Generic drag-and-drop file picker. Supports single or multiple files
// (via the `multiple` attribute on the file input) and, when the
// `sortable` value is true, lets the selected files be reordered by
// dragging their chips (used by the Merge PDFs tool).
export default class extends Controller {
  static targets = ["input", "list", "dropArea"]
  static values = { sortable: Boolean, accept: { type: String, default: "application/pdf" } }

  connect() {
    this.selectedFiles = []
  }

  browse() {
    this.inputTarget.click()
  }

  dragOver(event) {
    event.preventDefault()
    this.dropAreaTarget.classList.add("border-slate-900", "bg-slate-50")
  }

  dragLeave() {
    this.dropAreaTarget.classList.remove("border-slate-900", "bg-slate-50")
  }

  drop(event) {
    event.preventDefault()
    this.dropAreaTarget.classList.remove("border-slate-900", "bg-slate-50")
    this.addFiles(event.dataTransfer.files)
  }

  fileSelected() {
    this.addFiles(this.inputTarget.files)
  }

  addFiles(fileList) {
    const incoming = Array.from(fileList).filter((file) => file.type === this.acceptValue)

    this.selectedFiles = this.inputTarget.multiple ? this.selectedFiles.concat(incoming) : incoming.slice(0, 1)

    this.syncInput()
    this.renderList()
  }

  removeFile(event) {
    const index = Number(event.currentTarget.dataset.index)
    this.selectedFiles.splice(index, 1)
    this.syncInput()
    this.renderList()
  }

  syncInput() {
    const transfer = new DataTransfer()
    this.selectedFiles.forEach((file) => transfer.items.add(file))
    this.inputTarget.files = transfer.files
  }

  renderList() {
    if (!this.hasListTarget) return

    this.listTarget.innerHTML = ""

    this.selectedFiles.forEach((file, index) => {
      const item = document.createElement("li")
      item.className =
        "flex items-center justify-between rounded-md border border-slate-200 bg-white px-3 py-2 text-sm"
      item.draggable = this.sortableValue
      item.dataset.index = index

      const name = document.createElement("span")
      name.textContent = file.name
      name.className = "truncate"
      item.appendChild(name)

      const remove = document.createElement("button")
      remove.type = "button"
      remove.textContent = "×"
      remove.className = "ml-3 shrink-0 text-slate-400 hover:text-rose-600"
      remove.dataset.index = index
      remove.addEventListener("click", (event) => this.removeFile(event))
      item.appendChild(remove)

      if (this.sortableValue) {
        item.classList.add("cursor-move")
        item.addEventListener("dragstart", (event) => {
          event.dataTransfer.setData("text/plain", String(index))
        })
        item.addEventListener("dragover", (event) => event.preventDefault())
        item.addEventListener("drop", (event) => {
          event.preventDefault()
          event.stopPropagation()
          const from = Number(event.dataTransfer.getData("text/plain"))
          const [moved] = this.selectedFiles.splice(from, 1)
          this.selectedFiles.splice(index, 0, moved)
          this.syncInput()
          this.renderList()
        })
      }

      this.listTarget.appendChild(item)
    })
  }
}
