import { Controller } from "@hotwired/stimulus";

// Drag/drop uploader for a hidden <input type=file multiple>
// - Drop files from Finder onto the drop zone
// - Click drop zone to open the file picker
export default class extends Controller {
  static targets = ["input", "label"];

  connect() {
    this.onDragOver = (e) => {
      e.preventDefault();
      this.element.classList.add("ring-2", "ring-blue-500");
    };

    this.onDragLeave = (e) => {
      e.preventDefault();
      this.element.classList.remove("ring-2", "ring-blue-500");
    };

    this.onDrop = (e) => {
      e.preventDefault();
      this.element.classList.remove("ring-2", "ring-blue-500");

      const files = Array.from(e.dataTransfer?.files || []);
      if (files.length === 0) return;

      const dt = new DataTransfer();
      files.forEach((f) => dt.items.add(f));
      this.inputTarget.files = dt.files;

      this.updateLabel(files);
    };

    this.element.addEventListener("dragover", this.onDragOver);
    this.element.addEventListener("dragleave", this.onDragLeave);
    this.element.addEventListener("drop", this.onDrop);

    this.inputTarget.addEventListener("change", () => {
      const files = Array.from(this.inputTarget.files || []);
      this.updateLabel(files);
    });
  }

  disconnect() {
    this.element.removeEventListener("dragover", this.onDragOver);
    this.element.removeEventListener("dragleave", this.onDragLeave);
    this.element.removeEventListener("drop", this.onDrop);
  }

  open() {
    this.inputTarget.click();
  }

  updateLabel(files) {
    if (!this.hasLabelTarget) return;
    if (files.length === 0) {
      this.labelTarget.textContent = "Drag images here or click to choose";
      return;
    }

    if (files.length === 1) {
      this.labelTarget.textContent = files[0].name;
      return;
    }

    this.labelTarget.textContent = `${files.length} files selected`;
  }
}
