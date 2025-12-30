import { Controller } from "@hotwired/stimulus";

// Minimal carousel:
// - Arrow buttons (desktop)
// - Swipe (mobile/trackpads via pointer events)
// - No autoplay, no dots, no extra UI
export default class extends Controller {
  static targets = ["track"];
  static values = {
    index: { type: Number, default: 0 },
    count: { type: Number, default: 0 },
  };

  connect() {
    this._pointerId = null;
    this._startX = 0;
    this._lastX = 0;
    this._dragging = false;

    this.update();
  }

  prev(event) {
    event?.preventDefault();
    this.indexValue = Math.max(0, this.indexValue - 1);
    this.update();
  }

  next(event) {
    event?.preventDefault();
    this.indexValue = Math.min(this.countValue - 1, this.indexValue + 1);
    this.update();
  }

  pointerdown(event) {
    if (this.countValue <= 1) return;

    this._pointerId = event.pointerId;
    this._startX = event.clientX;
    this._lastX = event.clientX;
    this._dragging = true;

    this.trackTarget.setPointerCapture(this._pointerId);
    this.trackTarget.style.transition = "none";
  }

  pointermove(event) {
    if (!this._dragging || event.pointerId !== this._pointerId) return;

    this._lastX = event.clientX;

    const width = this.element.clientWidth || 1;
    const deltaX = this._lastX - this._startX;
    const base = -this.indexValue * width;

    this.trackTarget.style.transform = `translateX(${base + deltaX}px)`;
  }

  pointerup(event) {
    if (!this._dragging || event.pointerId !== this._pointerId) return;

    this._dragging = false;

    const width = this.element.clientWidth || 1;
    const deltaX = this._lastX - this._startX;
    const threshold = width * 0.15;

    this.trackTarget.style.transition = "transform 200ms ease";

    if (deltaX <= -threshold) {
      this.indexValue = Math.min(this.countValue - 1, this.indexValue + 1);
    } else if (deltaX >= threshold) {
      this.indexValue = Math.max(0, this.indexValue - 1);
    }

    this.update();

    try {
      this.trackTarget.releasePointerCapture(this._pointerId);
    } catch (_) {
      // noop
    }

    this._pointerId = null;
  }

  update() {
    if (!this.hasTrackTarget) return;

    const clampedCount = Math.max(0, this.countValue);
    const clampedIndex = Math.max(0, Math.min(clampedCount - 1, this.indexValue));

    this.indexValue = clampedIndex;

    const percent = clampedCount > 0 ? -(clampedIndex * 100) : 0;
    this.trackTarget.style.transition = this._dragging ? "none" : "transform 200ms ease";
    this.trackTarget.style.transform = `translateX(${percent}%)`;
  }
}
