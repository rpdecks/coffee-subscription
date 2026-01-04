require 'rails_helper'

RSpec.describe "User Registration with Email Confirmation", type: :request do
  describe "POST /users" do
    let(:valid_params) do
      {
        user: {
          email: 'newuser@example.com',
          password: 'SecurePassword123!',
          password_confirmation: 'SecurePassword123!',
          first_name: 'Jane',
          last_name: 'Doe'
        }
      }
    end

    context "when signing up" do
      it "creates a new unconfirmed user" do
        expect {
          post user_registration_path, params: valid_params
        }.to change(User, :count).by(1)

        user = User.last
        expect(user.confirmed?).to be false
        expect(user.confirmation_token).to be_present
      end

      it "sends confirmation email" do
        expect {
          post user_registration_path, params: valid_params
        }.to change { ActionMailer::Base.deliveries.count }.by(1)

        mail = ActionMailer::Base.deliveries.last
        expect(mail.to).to eq([ 'newuser@example.com' ])
        expect(mail.subject).to eq('Confirmation instructions')
      end

      it "redirects to root with message" do
        post user_registration_path, params: valid_params
        expect(response).to redirect_to(root_path)
      end

      it "shows a helpful message if confirmation email fails to send" do
        allow_any_instance_of(ActionMailer::MessageDelivery)
          .to receive(:deliver_now)
          .and_raise(Net::SMTPAuthenticationError.new("535 Authentication failed"))

        expect {
          post user_registration_path, params: valid_params
        }.to change(User, :count).by(1)

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to include("couldn't send the confirmation email")
      end
    end
  end

  describe "GET /users/confirmation" do
    let(:user) { create(:user, confirmed_at: nil) }

    before do
      user.send_confirmation_instructions
    end

    context "with valid token" do
      it "confirms the user" do
        get user_confirmation_path, params: { confirmation_token: user.confirmation_token }

        user.reload
        expect(user.confirmed?).to be true
      end

      it "redirects to sign in" do
        get user_confirmation_path, params: { confirmation_token: user.confirmation_token }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "with invalid token" do
      it "does not confirm the user" do
        get user_confirmation_path, params: { confirmation_token: 'invalid_token' }

        user.reload
        expect(user.confirmed?).to be false
      end

      it "shows error message" do
        get user_confirmation_path, params: { confirmation_token: 'invalid_token' }
        expect(response.body).to include("Confirmation token is invalid")
      end
    end
  end

  describe "POST /users/confirmation" do
    let(:user) { create(:user, :unconfirmed) }

    it "shows a helpful message if confirmation resend email fails to send" do
      allow_any_instance_of(ActionMailer::MessageDelivery)
        .to receive(:deliver_now)
        .and_raise(Net::SMTPAuthenticationError.new("535 Authentication failed"))

      post user_confirmation_path, params: { user: { email: user.email } }

      expect(response).to redirect_to(new_user_confirmation_path)
      expect(flash[:alert]).to include("couldn't send the confirmation email")
    end
  end

  describe "Sign in attempt" do
    context "when user is not confirmed" do
      let(:user) { create(:user, :unconfirmed, password: 'Password123!', password_confirmation: 'Password123!') }

      it "does not allow sign in" do
        post user_session_path, params: {
          user: {
            email: user.email,
            password: 'Password123!'
          }
        }

        expect(response).not_to redirect_to(dashboard_root_path)
      end
    end

    context "when user is confirmed" do
      let(:user) { create(:user, password: 'Password123!', password_confirmation: 'Password123!') }

      it "allows sign in" do
        post user_session_path, params: {
          user: {
            email: user.email,
            password: 'Password123!'
          }
        }

        # User should be signed in successfully
        expect(response).to have_http_status(:redirect)
        expect(response.location).to match(/\/(dashboard)?/)
      end
    end
  end
end
