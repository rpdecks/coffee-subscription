require "rails_helper"

RSpec.describe Admin::ProductionPlansController, type: :controller do
  let(:admin_user) { create(:admin_user) }

  before do
    allow(controller).to receive(:authenticate_user!).and_return(true)
    allow(controller).to receive(:require_admin!).and_return(true)
  end

  describe "GET #show" do
    it "renders the production plan" do
      get :show
      expect(response).to be_successful
      expect(assigns(:plan)).to be_present
    end
  end
end
