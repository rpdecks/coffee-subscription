require "rails_helper"

RSpec.describe "Admin::RoastEvents", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:roast_session) { create(:roast_session) }

  before { sign_in admin }

  describe "POST /admin/roast_sessions/:roast_session_id/roast_events" do
    let(:valid_params) do
      {
        roast_event: {
          time_seconds: 120,
          bean_temp_f: 300.0,
          manifold_wc: 0.9,
          air_position: "drum"
        }
      }
    end

    it "creates a data point event via JSON" do
      expect {
        post admin_roast_session_roast_events_path(roast_session),
             params: valid_params,
             as: :json
      }.to change(RoastEvent, :count).by(1)

      expect(response).to have_http_status(:created)

      json = JSON.parse(response.body)
      expect(json["time_seconds"]).to eq(120)
      expect(json["bean_temp_f"]).to eq(300.0)
    end

    it "creates a marker event" do
      marker_params = valid_params.deep_merge(roast_event: { event_type: "charge", time_seconds: 0 })

      expect {
        post admin_roast_session_roast_events_path(roast_session),
             params: marker_params,
             as: :json
      }.to change(RoastEvent, :count).by(1)

      event = RoastEvent.last
      expect(event).to be_event_type_charge
    end

    it "calculates metrics on DROP event" do
      create(:roast_event, :first_crack_start, roast_session: roast_session)

      drop_params = {
        roast_event: {
          time_seconds: 720,
          bean_temp_f: 420.0,
          manifold_wc: 0.8,
          air_position: "drum",
          event_type: "drop"
        }
      }

      post admin_roast_session_roast_events_path(roast_session),
           params: drop_params,
           as: :json

      roast_session.reload
      expect(roast_session.total_roast_time_seconds).to eq(720)
      expect(roast_session.development_time_seconds).to eq(180)
    end

    it "returns errors for invalid event" do
      post admin_roast_session_roast_events_path(roast_session),
           params: { roast_event: { time_seconds: -1 } },
           as: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
