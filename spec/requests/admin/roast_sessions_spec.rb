require "rails_helper"

RSpec.describe "Admin::RoastSessions", type: :request do
  let(:admin) { create(:user, :admin) }

  before { sign_in admin }

  describe "GET /admin/roast_sessions" do
    it "renders the index page" do
      create(:roast_session)
      get admin_roast_sessions_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /admin/roast_sessions/new" do
    it "renders the new form" do
      get new_admin_roast_session_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /admin/roast_sessions" do
    let(:valid_params) do
      {
        roast_session: {
          coffee_name: "Ethiopia Yirgacheffe",
          batch_size_g: 450,
          process: "Washed",
          gas_type: "lp",
          ambient_temp_f: 72,
          charge_temp_target_f: 400
        }
      }
    end

    it "creates a roast session and redirects" do
      expect {
        post admin_roast_sessions_path, params: valid_params
      }.to change(RoastSession, :count).by(1)

      session = RoastSession.last
      expect(session.coffee_name).to eq("Ethiopia Yirgacheffe")
      expect(session.started_at).to be_present
      expect(response).to redirect_to(admin_roast_session_path(session))
    end

    it "renders new on invalid params" do
      post admin_roast_sessions_path, params: { roast_session: { coffee_name: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /admin/roast_sessions/:id" do
    it "renders the show page" do
      session = create(:roast_session)
      get admin_roast_session_path(session)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /admin/roast_sessions/:id" do
    it "updates the session" do
      session = create(:roast_session)
      patch admin_roast_session_path(session), params: { roast_session: { notes: "Good roast" } }
      expect(session.reload.notes).to eq("Good roast")
      expect(response).to redirect_to(admin_roast_session_path(session))
    end
  end

  describe "PATCH /admin/roast_sessions/:id/end_roast" do
    it "ends the roast and calculates metrics" do
      session = create(:roast_session)
      create(:roast_event, :first_crack_start, roast_session: session)
      create(:roast_event, :drop, roast_session: session)

      patch end_roast_admin_roast_session_path(session)

      session.reload
      expect(session.ended_at).to be_present
      expect(session.total_roast_time_seconds).to eq(720)
      expect(response).to redirect_to(admin_roast_session_path(session))
    end
  end

  describe "GET /admin/roast_sessions/:id/export" do
    it "returns a CSV file" do
      session = create(:roast_session, :with_events)
      get export_admin_roast_session_path(session)
      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include("text/csv")
    end
  end

  describe "DELETE /admin/roast_sessions/:id" do
    it "deletes the session" do
      session = create(:roast_session)
      expect {
        delete admin_roast_session_path(session)
      }.to change(RoastSession, :count).by(-1)
      expect(response).to redirect_to(admin_roast_sessions_path)
    end
  end

  context "when not admin" do
    let(:customer) { create(:user, :customer) }

    before { sign_in customer }

    it "denies access" do
      get admin_roast_sessions_path
      expect(response).to redirect_to(root_path)
    end
  end

  context "when not signed in" do
    before { sign_out admin }

    it "redirects to sign in" do
      get admin_roast_sessions_path
      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
