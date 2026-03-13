import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "cropFrame",
    "cropImage",
    "editor",
    "error",
    "existingPreview",
    "input",
    "livePreview",
    "removeCheckbox",
    "status",
    "zoom",
    "zoomValue"
  ];

  static values = {
    cropSize: { type: Number, default: 240 },
    maxFileSize: Number,
    maxZoom: { type: Number, default: 3 },
    outputSize: { type: Number, default: 400 },
    previewSize: { type: Number, default: 96 }
  };

  connect() {
    this.defaultStatus = this.statusTarget.textContent.trim();
    this.submissionPrepared = false;
    this.zoomLevel = 1;
    this.updateZoomLabel();
  }

  disconnect() {
    this.revokeObjectUrl();
  }

  fileChanged(event) {
    const file = event.target.files[0];

    if (!file) {
      this.clearSelection();
      return;
    }

    const error = this.validateFile(file);

    if (error) {
      this.inputTarget.value = "";
      this.showError(error);
      this.clearSelection();
      return;
    }

    this.hideError();
    this.submissionPrepared = false;

    if (this.hasRemoveCheckboxTarget) {
      this.removeCheckboxTarget.checked = false;
    }

    this.loadFile(file);
  }

  async prepareSubmission(event) {
    if (this.submissionPrepared || !this.sourceFile || !this.inputTarget.files.length) {
      return;
    }

    event.preventDefault();

    const submitter = event.submitter;
    const blob = await this.renderBlob(this.outputSizeValue);

    if (!blob) {
      this.showError("Could not prepare your profile photo. Please choose the image again.");
      return;
    }

    if (blob.size > this.maxFileSizeValue) {
      this.showError("The cropped image is still larger than 5 MB. Please zoom out or choose a smaller file.");
      return;
    }

    const extension = blob.type === "image/png" ? "png" : "jpg";
    const file = new File([blob], this.buildFilename(extension), {
      type: blob.type,
      lastModified: Date.now()
    });
    const transfer = new DataTransfer();

    transfer.items.add(file);
    this.inputTarget.files = transfer.files;
    this.submissionPrepared = true;

    if (submitter) {
      this.element.requestSubmit(submitter);
    } else {
      this.element.requestSubmit();
    }
  }

  resetCrop() {
    if (!this.sourceImage) {
      return;
    }

    this.zoomLevel = 1;
    this.zoomTarget.value = "1";
    this.centerImage();
    this.refreshCropUi();
  }

  startDrag(event) {
    if (!this.sourceImage) {
      return;
    }

    this.dragPointerId = event.pointerId;
    this.dragOriginX = this.offsetX;
    this.dragOriginY = this.offsetY;
    this.dragStartX = event.clientX;
    this.dragStartY = event.clientY;
    this.cropFrameTarget.setPointerCapture(event.pointerId);
  }

  drag(event) {
    if (this.dragPointerId !== event.pointerId || !this.sourceImage) {
      return;
    }

    this.offsetX = this.dragOriginX + event.clientX - this.dragStartX;
    this.offsetY = this.dragOriginY + event.clientY - this.dragStartY;
    this.clampOffsets();
    this.refreshCropUi();
  }

  endDrag(event) {
    if (this.dragPointerId !== event.pointerId) {
      return;
    }

    this.cropFrameTarget.releasePointerCapture(event.pointerId);
    this.dragPointerId = null;
  }

  toggleRemove() {
    if (!this.hasRemoveCheckboxTarget) {
      return;
    }

    if (this.removeCheckboxTarget.checked) {
      this.inputTarget.value = "";
      this.clearSelection();
      this.statusTarget.textContent = "Photo will be removed when you save";
      this.hideError();
      return;
    }

    this.statusTarget.textContent = this.defaultStatus;
  }

  zoomChanged() {
    if (!this.sourceImage) {
      this.updateZoomLabel();
      return;
    }

    const previousScale = this.displayScale;
    const focusX = (this.cropSizeValue / 2 - this.offsetX) / previousScale;
    const focusY = (this.cropSizeValue / 2 - this.offsetY) / previousScale;

    this.zoomLevel = Number(this.zoomTarget.value);

    this.offsetX = this.cropSizeValue / 2 - focusX * this.displayScale;
    this.offsetY = this.cropSizeValue / 2 - focusY * this.displayScale;
    this.clampOffsets();
    this.refreshCropUi();
  }

  get displayHeight() {
    return this.sourceImage.naturalHeight * this.displayScale;
  }

  get displayScale() {
    return this.minimumScale * this.zoomLevel;
  }

  get displayWidth() {
    return this.sourceImage.naturalWidth * this.displayScale;
  }

  buildFilename(extension) {
    const originalName = this.sourceFile.name.replace(/\.[^.]+$/, "");
    return `${originalName || "profile-photo"}-cropped.${extension}`;
  }

  centerImage() {
    this.offsetX = (this.cropSizeValue - this.displayWidth) / 2;
    this.offsetY = (this.cropSizeValue - this.displayHeight) / 2;
  }

  clampOffsets() {
    this.offsetX = Math.min(0, Math.max(this.cropSizeValue - this.displayWidth, this.offsetX));
    this.offsetY = Math.min(0, Math.max(this.cropSizeValue - this.displayHeight, this.offsetY));
  }

  clearSelection() {
    this.revokeObjectUrl();
    this.sourceFile = null;
    this.sourceImage = null;
    this.submissionPrepared = false;
    this.dragPointerId = null;
    this.editorTarget.classList.add("hidden");
    this.livePreviewTarget.classList.add("hidden");
    this.existingPreviewTarget.classList.remove("hidden");
    this.zoomTarget.value = "1";
    this.zoomLevel = 1;
    this.updateZoomLabel();

    if (!this.hasRemoveCheckboxTarget || !this.removeCheckboxTarget.checked) {
      this.statusTarget.textContent = this.defaultStatus;
    }
  }

  drawToCanvas(size) {
    const canvas = document.createElement("canvas");
    const context = canvas.getContext("2d");
    const sourceX = -this.offsetX / this.displayScale;
    const sourceY = -this.offsetY / this.displayScale;
    const sourceSize = this.cropSizeValue / this.displayScale;

    canvas.width = size;
    canvas.height = size;
    context.drawImage(
      this.sourceImage,
      sourceX,
      sourceY,
      sourceSize,
      sourceSize,
      0,
      0,
      size,
      size
    );

    return canvas;
  }

  hideError() {
    this.errorTarget.classList.add("hidden");
    this.errorTarget.querySelector("p").textContent = "";
  }

  async loadFile(file) {
    this.revokeObjectUrl();
    this.objectUrl = URL.createObjectURL(file);

    try {
      this.sourceImage = await this.readImage(this.objectUrl);
    } catch (_error) {
      this.inputTarget.value = "";
      this.showError("That image could not be loaded. Please choose a different file.");
      this.clearSelection();
      return;
    }

    this.sourceFile = file;
    this.minimumScale = Math.max(
      this.cropSizeValue / this.sourceImage.naturalWidth,
      this.cropSizeValue / this.sourceImage.naturalHeight
    );
    this.zoomLevel = 1;
    this.zoomTarget.value = "1";
    this.centerImage();
    this.editorTarget.classList.remove("hidden");
    this.refreshCropUi();
    this.statusTarget.textContent = `New photo selected: ${file.name}`;
  }

  outputType() {
    return this.sourceFile.type === "image/png" ? "image/png" : "image/jpeg";
  }

  readImage(url) {
    return new Promise((resolve, reject) => {
      const image = new Image();

      image.onload = () => resolve(image);
      image.onerror = () => reject(new Error("Image load failed"));
      image.src = url;
    });
  }

  refreshCropUi() {
    this.cropImageTarget.src = this.objectUrl;
    this.cropImageTarget.style.width = `${this.displayWidth}px`;
    this.cropImageTarget.style.height = `${this.displayHeight}px`;
    this.cropImageTarget.style.transform = `translate(${this.offsetX}px, ${this.offsetY}px)`;
    this.updateZoomLabel();

    const previewCanvas = this.drawToCanvas(this.previewSizeValue);

    this.livePreviewTarget.src = previewCanvas.toDataURL(this.outputType(), 0.92);
    this.livePreviewTarget.classList.remove("hidden");
    this.existingPreviewTarget.classList.add("hidden");
  }

  renderBlob(size) {
    const canvas = this.drawToCanvas(size);

    return new Promise((resolve) => {
      canvas.toBlob((blob) => resolve(blob), this.outputType(), 0.92);
    });
  }

  revokeObjectUrl() {
    if (this.objectUrl) {
      URL.revokeObjectURL(this.objectUrl);
      this.objectUrl = null;
    }
  }

  showError(message) {
    this.errorTarget.classList.remove("hidden");
    this.errorTarget.querySelector("p").textContent = message;
  }

  updateZoomLabel() {
    this.zoomValueTarget.textContent = `${Math.round(Number(this.zoomTarget.value || this.zoomLevel || 1) * 100)}%`;
  }

  validateFile(file) {
    if (!["image/png", "image/jpeg", "image/webp"].includes(file.type)) {
      return "Please choose a PNG, JPEG, or WebP image.";
    }

    if (file.size > this.maxFileSizeValue) {
      const sizeMB = (file.size / 1024 / 1024).toFixed(2);
      const maxSizeMB = (this.maxFileSizeValue / 1024 / 1024).toFixed(0);
      return `File size (${sizeMB} MB) exceeds the ${maxSizeMB} MB limit.`;
    }

    return null;
  }
}