require 'rails_helper'

RSpec.describe "Dashboard::Addresses", type: :request do
  let(:user) { FactoryBot.create(:user) }
  let(:address) { FactoryBot.create(:address, user: user) }

  before { sign_in user }

  describe "GET /dashboard/addresses" do
    it "returns http success" do
      get dashboard_addresses_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /dashboard/addresses/new" do
    it "returns http success" do
      get new_dashboard_address_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /dashboard/addresses" do
    it "creates an address" do
      expect {
        post dashboard_addresses_path, params: { address: FactoryBot.attributes_for(:address) }
      }.to change(Address, :count).by(1)
    end
  end

  describe "GET /dashboard/addresses/:id/edit" do
    it "returns http success" do
      get edit_dashboard_address_path(address)
      expect(response).to have_http_status(:success)
    end
  end

  describe "PATCH /dashboard/addresses/:id" do
    it "updates the address" do
      patch dashboard_address_path(address), params: { address: { street: "New Street" } }
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "DELETE /dashboard/addresses/:id" do
    it "destroys the address" do
      address # create it
      expect {
        delete dashboard_address_path(address)
      }.to change(Address, :count).by(-1)
    end
  end
end
