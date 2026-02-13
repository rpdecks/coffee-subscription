require "rails_helper"

RSpec.describe RoastSession, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:coffee_name) }
    it { is_expected.to validate_presence_of(:batch_size_g) }
    it { is_expected.to validate_numericality_of(:batch_size_g).is_greater_than(0) }
    it { is_expected.to validate_numericality_of(:ambient_temp_f).allow_nil }
    it { is_expected.to validate_numericality_of(:charge_temp_target_f).allow_nil }
    it { is_expected.to validate_numericality_of(:green_weight_g).is_greater_than(0).allow_nil }
    it { is_expected.to validate_numericality_of(:roasted_weight_g).is_greater_than(0).allow_nil }
  end

  describe "associations" do
    it { is_expected.to have_many(:roast_events).dependent(:destroy) }
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:gas_type).with_values(lp: 0, ng: 1).with_prefix(:gas_type) }
  end

  describe "scopes" do
    describe ".recent" do
      it "orders by started_at descending" do
        old = create(:roast_session, started_at: 2.days.ago)
        recent = create(:roast_session, started_at: 1.hour.ago)
        expect(RoastSession.recent).to eq([ recent, old ])
      end
    end

    describe ".completed" do
      it "returns only completed sessions" do
        active = create(:roast_session)
        completed = create(:roast_session, :completed)
        expect(RoastSession.completed).to include(completed)
        expect(RoastSession.completed).not_to include(active)
      end
    end

    describe ".in_progress" do
      it "returns only active sessions" do
        active = create(:roast_session)
        completed = create(:roast_session, :completed)
        expect(RoastSession.in_progress).to include(active)
        expect(RoastSession.in_progress).not_to include(completed)
      end
    end
  end

  describe "#active?" do
    it "returns true when started but not ended" do
      session = build(:roast_session, started_at: Time.current, ended_at: nil)
      expect(session).to be_active
    end

    it "returns false when ended" do
      session = build(:roast_session, :completed)
      expect(session).not_to be_active
    end
  end

  describe "#formatted_duration" do
    it "formats total roast time in m:ss" do
      session = build(:roast_session, total_roast_time_seconds: 723)
      expect(session.formatted_duration).to eq("12:03")
    end

    it "returns --:-- when no time data" do
      session = build(:roast_session, started_at: nil)
      expect(session.formatted_duration).to eq("--:--")
    end
  end

  describe "#calculate_derived_metrics!" do
    it "calculates total roast time from DROP event" do
      session = create(:roast_session)
      create(:roast_event, :drop, roast_session: session, time_seconds: 720)

      session.calculate_derived_metrics!
      session.reload

      expect(session.total_roast_time_seconds).to eq(720)
      expect(session.ended_at).to be_present
    end

    it "calculates development time and ratio" do
      session = create(:roast_session)
      create(:roast_event, :first_crack_start, roast_session: session, time_seconds: 540)
      create(:roast_event, :drop, roast_session: session, time_seconds: 720)

      session.calculate_derived_metrics!
      session.reload

      expect(session.development_time_seconds).to eq(180)
      expect(session.development_ratio).to eq(25.0)
    end

    it "calculates weight loss percentage" do
      session = create(:roast_session, green_weight_g: 450, roasted_weight_g: 382)
      create(:roast_event, :drop, roast_session: session, time_seconds: 720)

      session.calculate_derived_metrics!
      session.reload

      expect(session.weight_loss_percent).to eq(15.1)
    end
  end

  describe "#to_csv_row" do
    it "returns an array of values" do
      session = create(:roast_session)
      expect(session.to_csv_row).to be_an(Array)
      expect(session.to_csv_row.length).to eq(RoastSession.csv_headers.length)
    end
  end
end
