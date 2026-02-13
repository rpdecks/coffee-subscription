class RoastEvent < ApplicationRecord
  belongs_to :roast_session

  # Enums
  enum :air_position, { cooling: 0, fifty_fifty: 1, drum: 2 }, prefix: true
  enum :event_type, {
    charge: 0,
    turning_point: 1,
    yellow: 2,
    cinnamon: 3,
    first_crack_start: 4,
    first_crack_rolling: 5,
    first_crack_end: 6,
    drop: 7
  }, prefix: true

  # Validations
  validates :time_seconds, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :bean_temp_f, numericality: { allow_nil: true }
  validates :manifold_wc, numericality: { allow_nil: true }

  # Scopes
  scope :chronological, -> { order(:time_seconds) }
  scope :markers, -> { where.not(event_type: nil) }
  scope :data_points, -> { where(event_type: nil) }

  # Display helpers
  def formatted_time
    format("%d:%02d", time_seconds / 60, time_seconds % 60)
  end

  def air_position_display
    case air_position
    when "cooling" then "Cooling"
    when "fifty_fifty" then "50/50"
    when "drum" then "Drum"
    end
  end

  def event_type_display
    return nil unless event_type
    case event_type
    when "charge" then "CHARGE"
    when "turning_point" then "TP"
    when "yellow" then "YELLOW"
    when "cinnamon" then "CINNAMON"
    when "first_crack_start" then "1C START"
    when "first_crack_rolling" then "1C ROLLING"
    when "first_crack_end" then "1C END"
    when "drop" then "DROP"
    end
  end

  # CSV export
  def to_csv_row
    [
      roast_session_id, time_seconds, formatted_time,
      bean_temp_f, manifold_wc, air_position,
      event_type, notes
    ]
  end

  def self.csv_headers
    %w[
      roast_session_id time_seconds formatted_time
      bean_temp_f manifold_wc air_position
      event_type notes
    ]
  end
end
