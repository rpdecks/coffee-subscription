class RoastSession < ApplicationRecord
  has_many :roast_events, -> { order(:time_seconds) }, dependent: :destroy

  # Enums
  enum :gas_type, { lp: 0, ng: 1 }, prefix: true

  # Validations
  validates :coffee_name, presence: true
  validates :batch_size_g, presence: true, numericality: { greater_than: 0 }
  validates :ambient_temp_f, numericality: { allow_nil: true }
  validates :charge_temp_target_f, numericality: { allow_nil: true }
  validates :green_weight_g, numericality: { greater_than: 0, allow_nil: true }
  validates :roasted_weight_g, numericality: { greater_than: 0, allow_nil: true }

  # Scopes
  scope :recent, -> { order(started_at: :desc) }
  scope :completed, -> { where.not(ended_at: nil) }
  scope :in_progress, -> { where(ended_at: nil).where.not(started_at: nil) }

  # Status helpers
  def active?
    started_at.present? && ended_at.nil?
  end

  def completed?
    ended_at.present?
  end

  def duration_seconds
    return nil unless started_at
    return total_roast_time_seconds if total_roast_time_seconds
    (Time.current - started_at).to_i
  end

  # Derived metric calculations — called when DROP event is logged
  def calculate_derived_metrics!
    drop_event = roast_events.find_by(event_type: :drop)
    fc_start_event = roast_events.find_by(event_type: :first_crack_start)

    attrs = {}

    if drop_event
      attrs[:total_roast_time_seconds] = drop_event.time_seconds
      attrs[:ended_at] = started_at + drop_event.time_seconds.seconds if started_at

      if fc_start_event
        dev_time = drop_event.time_seconds - fc_start_event.time_seconds
        attrs[:development_time_seconds] = dev_time
        attrs[:development_ratio] = (dev_time.to_f / drop_event.time_seconds * 100).round(1) if drop_event.time_seconds > 0
      end
    end

    if green_weight_g.present? && roasted_weight_g.present? && green_weight_g > 0
      attrs[:weight_loss_percent] = ((green_weight_g - roasted_weight_g).to_f / green_weight_g * 100).round(1)
    end

    update!(attrs) if attrs.any?
  end

  # Format helpers
  def formatted_duration
    seconds = total_roast_time_seconds || duration_seconds
    return "--:--" unless seconds
    format("%d:%02d", seconds / 60, seconds % 60)
  end

  def formatted_development_time
    return nil unless development_time_seconds
    format("%d:%02d", development_time_seconds / 60, development_time_seconds % 60)
  end

  # CSV export support
  def to_csv_row
    [
      id, coffee_name, lot_id, process, batch_size_g,
      ambient_temp_f, charge_temp_target_f, gas_type,
      green_weight_g, roasted_weight_g,
      started_at&.iso8601, ended_at&.iso8601,
      total_roast_time_seconds, development_time_seconds,
      development_ratio, weight_loss_percent, notes
    ]
  end

  def self.csv_headers
    %w[
      id coffee_name lot_id process batch_size_g
      ambient_temp_f charge_temp_target_f gas_type
      green_weight_g roasted_weight_g
      started_at ended_at
      total_roast_time_seconds development_time_seconds
      development_ratio weight_loss_percent notes
    ]
  end
end
