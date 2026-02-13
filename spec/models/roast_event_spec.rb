require "rails_helper"

RSpec.describe RoastEvent, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:time_seconds) }
    it { is_expected.to validate_numericality_of(:time_seconds).is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_numericality_of(:bean_temp_f).allow_nil }
    it { is_expected.to validate_numericality_of(:manifold_wc).allow_nil }
  end

  describe "associations" do
    it { is_expected.to belong_to(:roast_session) }
  end

  describe "enums" do
    it do
      is_expected.to define_enum_for(:air_position)
        .with_values(cooling: 0, fifty_fifty: 1, drum: 2)
        .with_prefix(:air_position)
    end

    it do
      is_expected.to define_enum_for(:event_type)
        .with_values(
          charge: 0,
          turning_point: 1,
          yellow: 2,
          cinnamon: 3,
          first_crack_start: 4,
          first_crack_rolling: 5,
          first_crack_end: 6,
          drop: 7
        )
        .with_prefix(:event_type)
    end
  end

  describe "scopes" do
    let(:session) { create(:roast_session) }

    describe ".chronological" do
      it "orders by time_seconds ascending" do
        late = create(:roast_event, roast_session: session, time_seconds: 300)
        early = create(:roast_event, roast_session: session, time_seconds: 60)
        expect(RoastEvent.chronological).to eq([ early, late ])
      end
    end

    describe ".markers" do
      it "returns only events with event_type" do
        marker = create(:roast_event, :charge, roast_session: session)
        data_point = create(:roast_event, roast_session: session)
        expect(RoastEvent.markers).to include(marker)
        expect(RoastEvent.markers).not_to include(data_point)
      end
    end

    describe ".data_points" do
      it "returns only events without event_type" do
        marker = create(:roast_event, :charge, roast_session: session)
        data_point = create(:roast_event, roast_session: session)
        expect(RoastEvent.data_points).to include(data_point)
        expect(RoastEvent.data_points).not_to include(marker)
      end
    end
  end

  describe "#formatted_time" do
    it "formats seconds as m:ss" do
      event = build(:roast_event, time_seconds: 125)
      expect(event.formatted_time).to eq("2:05")
    end

    it "formats zero correctly" do
      event = build(:roast_event, time_seconds: 0)
      expect(event.formatted_time).to eq("0:00")
    end
  end

  describe "#air_position_display" do
    it "returns human-readable air position" do
      expect(build(:roast_event, air_position: :fifty_fifty).air_position_display).to eq("50/50")
      expect(build(:roast_event, air_position: :drum).air_position_display).to eq("Drum")
      expect(build(:roast_event, air_position: :cooling).air_position_display).to eq("Cooling")
    end
  end

  describe "#event_type_display" do
    it "returns nil for data points" do
      expect(build(:roast_event, event_type: nil).event_type_display).to be_nil
    end

    it "returns display string for markers" do
      expect(build(:roast_event, event_type: :first_crack_start).event_type_display).to eq("1C START")
      expect(build(:roast_event, event_type: :drop).event_type_display).to eq("DROP")
    end
  end

  describe "#to_csv_row" do
    it "returns an array matching csv_headers length" do
      event = create(:roast_event)
      expect(event.to_csv_row.length).to eq(RoastEvent.csv_headers.length)
    end
  end
end
