import { Controller } from "@hotwired/stimulus";

// Chart.js is loaded via importmap CDN pin
let Chart = null;

export default class extends Controller {
  static targets = [
    "timer",
    "entryForm",
    "beanTemp",
    "manifoldWc",
    "airPosition",
    "notes",
    "eventLog",
    "chart",
  ];

  static values = {
    sessionId: Number,
    startedAt: String,
    active: Boolean,
    eventsUrl: String,
    existingEvents: Array,
  };

  connect() {
    this.elapsedSeconds = 0;
    this.events = this.existingEventsValue || [];
    this.chartInstance = null;

    if (this.activeValue) {
      this._startTimer();
    }

    this._initChart();
  }

  disconnect() {
    if (this.timerInterval) {
      clearInterval(this.timerInterval);
    }
    if (this.chartInstance) {
      this.chartInstance.destroy();
    }
  }

  // ── Timer ──────────────────────────────────────────────

  _startTimer() {
    const startedAt = new Date(this.startedAtValue);
    this._updateTimer(startedAt);
    this.timerInterval = setInterval(() => this._updateTimer(startedAt), 1000);
  }

  _updateTimer(startedAt) {
    const now = new Date();
    this.elapsedSeconds = Math.floor((now - startedAt) / 1000);
    const mins = Math.floor(this.elapsedSeconds / 60);
    const secs = this.elapsedSeconds % 60;
    if (this.hasTimerTarget) {
      this.timerTarget.textContent = `${mins}:${secs.toString().padStart(2, "0")}`;
    }
  }

  // ── Log Entry ──────────────────────────────────────────

  async logEntry(e) {
    e.preventDefault();

    const beanTemp = parseFloat(this.beanTempTarget.value);
    const manifoldWc = parseFloat(this.manifoldWcTarget.value);

    if (isNaN(beanTemp) || isNaN(manifoldWc)) {
      this._flash("Bean temp and manifold pressure are required.");
      return;
    }

    const data = {
      roast_event: {
        time_seconds: this.elapsedSeconds,
        bean_temp_f: beanTemp,
        manifold_wc: manifoldWc,
        air_position: this.airPositionTarget.value,
        notes: this.notesTarget.value || null,
      },
    };

    await this._saveEvent(data);

    // Clear notes only, keep temp/pressure for rapid re-entry
    this.notesTarget.value = "";
    this.beanTempTarget.focus();
    this.beanTempTarget.select();
  }

  // ── Event Markers ──────────────────────────────────────

  async logMarker(e) {
    const eventType = e.params.eventType;

    // Use current form values if available, otherwise null
    const beanTemp = this.hasBeanTempTarget ? parseFloat(this.beanTempTarget.value) : null;
    const manifoldWc = this.hasManifoldWcTarget ? parseFloat(this.manifoldWcTarget.value) : null;

    const data = {
      roast_event: {
        time_seconds: this.elapsedSeconds,
        bean_temp_f: isNaN(beanTemp) ? null : beanTemp,
        manifold_wc: isNaN(manifoldWc) ? null : manifoldWc,
        air_position: this.hasAirPositionTarget ? this.airPositionTarget.value : "drum",
        event_type: eventType,
      },
    };

    await this._saveEvent(data);
  }

  // ── Network ────────────────────────────────────────────

  async _saveEvent(data) {
    try {
      const response = await fetch(this.eventsUrlValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
          Accept: "application/json",
        },
        body: JSON.stringify(data),
      });

      if (!response.ok) {
        const err = await response.json();
        this._flash(err.errors ? err.errors.join(", ") : "Failed to save event.");
        return;
      }

      const event = await response.json();
      this.events.push(event);
      this._appendEventRow(event);
      this._updateChart(event);

      // If DROP event, reload page to show metrics
      if (event.event_type === "drop") {
        setTimeout(() => window.location.reload(), 500);
      }
    } catch (err) {
      console.error("Save event failed:", err);
      this._flash("Network error. Check connection.");
    }
  }

  // ── Event Log Table ────────────────────────────────────

  _appendEventRow(event) {
    if (!this.hasEventLogTarget) return;

    const mins = Math.floor(event.time_seconds / 60);
    const secs = event.time_seconds % 60;
    const formattedTime = `${mins}:${secs.toString().padStart(2, "0")}`;

    const airDisplay =
      { cooling: "Cooling", fifty_fifty: "50/50", drum: "Drum" }[event.air_position] || "";

    const eventBadge = event.event_type_display
      ? `<span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-bold ${this._eventBadgeClass(event.event_type)}">${event.event_type_display}</span>`
      : "";

    const isMarker = event.event_type ? "bg-amber-50" : "";

    const row = document.createElement("tr");
    row.className = isMarker;
    row.innerHTML = `
      <td class="px-3 py-1.5 font-mono text-gray-700">${formattedTime}</td>
      <td class="px-3 py-1.5 font-mono font-semibold text-gray-900">${event.bean_temp_f || ""}</td>
      <td class="px-3 py-1.5 font-mono text-gray-700">${event.manifold_wc || ""}</td>
      <td class="px-3 py-1.5 text-gray-600">${airDisplay}</td>
      <td class="px-3 py-1.5">${eventBadge}</td>
      <td class="px-3 py-1.5 text-gray-500 text-xs">${event.notes || ""}</td>
    `;
    this.eventLogTarget.appendChild(row);

    // Auto-scroll to bottom
    row.scrollIntoView({ behavior: "smooth", block: "nearest" });
  }

  _eventBadgeClass(eventType) {
    const classes = {
      charge: "bg-blue-100 text-blue-800",
      turning_point: "bg-cyan-100 text-cyan-800",
      yellow: "bg-yellow-100 text-yellow-800",
      cinnamon: "bg-amber-100 text-amber-800",
      first_crack_start: "bg-orange-100 text-orange-800",
      first_crack_rolling: "bg-orange-100 text-orange-800",
      first_crack_end: "bg-red-100 text-red-800",
      drop: "bg-red-200 text-red-900",
    };
    return classes[eventType] || "bg-gray-100 text-gray-800";
  }

  // ── Chart ──────────────────────────────────────────────

  async _initChart() {
    if (!this.hasChartTarget) return;

    // Dynamically import Chart.js
    try {
      const chartModule = await import("chart.js");
      Chart = chartModule.Chart || chartModule.default;
      // Register all components
      if (Chart.register) {
        const components = [
          chartModule.LineController,
          chartModule.LineElement,
          chartModule.PointElement,
          chartModule.LinearScale,
          chartModule.CategoryScale,
          chartModule.Filler,
          chartModule.Legend,
          chartModule.Tooltip,
        ].filter(Boolean);
        if (components.length > 0) {
          Chart.register(...components);
        }
      }
    } catch (e) {
      // chart.js UMD build registers on window.Chart
      Chart = window.Chart;
    }

    if (!Chart) {
      console.warn("Chart.js not available");
      return;
    }

    const ctx = this.chartTarget.getContext("2d");
    const dataPoints = this.events.filter((e) => e.bean_temp_f != null);
    const markers = this.events.filter((e) => e.event_type != null && e.bean_temp_f != null);

    this.chartInstance = new Chart(ctx, {
      type: "line",
      data: {
        labels: dataPoints.map((e) => this._formatSeconds(e.time_seconds)),
        datasets: [
          {
            label: "Bean Temp (°F)",
            data: dataPoints.map((e) => e.bean_temp_f),
            borderColor: "#d97706",
            backgroundColor: "rgba(217, 119, 6, 0.1)",
            borderWidth: 2,
            tension: 0.3,
            fill: true,
            yAxisID: "y",
            pointRadius: dataPoints.map((e) =>
              markers.find((m) => m.time_seconds === e.time_seconds) ? 6 : 2
            ),
            pointBackgroundColor: dataPoints.map((e) => {
              const marker = markers.find((m) => m.time_seconds === e.time_seconds);
              return marker ? "#dc2626" : "#d97706";
            }),
          },
          {
            label: "Manifold (wc)",
            data: dataPoints.map((e) => e.manifold_wc),
            borderColor: "#3b82f6",
            backgroundColor: "rgba(59, 130, 246, 0.05)",
            borderWidth: 1.5,
            tension: 0.3,
            fill: false,
            yAxisID: "y1",
            pointRadius: 1,
          },
        ],
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        interaction: {
          mode: "index",
          intersect: false,
        },
        plugins: {
          legend: {
            position: "top",
            labels: { usePointStyle: true, padding: 15 },
          },
          tooltip: {
            callbacks: {
              afterBody: (items) => {
                const idx = items[0]?.dataIndex;
                if (idx == null) return "";
                const dp = dataPoints[idx];
                const marker = markers.find((m) => m.time_seconds === dp.time_seconds);
                return marker ? `⚑ ${marker.event_type_display}` : "";
              },
            },
          },
        },
        scales: {
          x: {
            title: { display: true, text: "Time" },
            ticks: { maxTicksLimit: 20 },
          },
          y: {
            type: "linear",
            position: "left",
            title: { display: true, text: "Bean Temp (°F)" },
            suggestedMin: 150,
            suggestedMax: 450,
          },
          y1: {
            type: "linear",
            position: "right",
            title: { display: true, text: "Manifold (wc)" },
            grid: { drawOnChartArea: false },
            suggestedMin: 0,
            suggestedMax: 2.0,
          },
        },
        // Future: RoR dataset can be added as a third dataset
      },
    });
  }

  _updateChart(event) {
    if (!this.chartInstance || event.bean_temp_f == null) return;

    const label = this._formatSeconds(event.time_seconds);
    this.chartInstance.data.labels.push(label);
    this.chartInstance.data.datasets[0].data.push(event.bean_temp_f);
    this.chartInstance.data.datasets[1].data.push(event.manifold_wc);

    // Update point styling for markers
    const isMarker = event.event_type != null;
    this.chartInstance.data.datasets[0].pointRadius.push(isMarker ? 6 : 2);
    this.chartInstance.data.datasets[0].pointBackgroundColor.push(isMarker ? "#dc2626" : "#d97706");

    this.chartInstance.update("none"); // skip animation for real-time feel
  }

  // ── Helpers ────────────────────────────────────────────

  _formatSeconds(totalSeconds) {
    const mins = Math.floor(totalSeconds / 60);
    const secs = totalSeconds % 60;
    return `${mins}:${secs.toString().padStart(2, "0")}`;
  }

  _flash(message) {
    const existing = document.getElementById("event-errors");
    if (existing) {
      existing.innerHTML = `
        <div class="bg-red-50 border border-red-200 text-red-700 px-3 py-2 rounded-lg mb-3 text-sm">
          ${message}
        </div>
      `;
      setTimeout(() => {
        existing.innerHTML = "";
      }, 4000);
    }
  }
}
