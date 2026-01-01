require 'rails_helper'

RSpec.describe "Dashboard::Profiles", type: :request do
  let(:user) { FactoryBot.create(:user) }

  before { sign_in user }

  describe "GET /dashboard/profile/edit" do
    it "returns http success" do
      get edit_dashboard_profile_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "PATCH /dashboard/profile" do
    it "updates profile" do
      patch dashboard_profile_path, params: { user: { first_name: "New Name" } }
      expect(response).to have_http_status(:redirect)
    end

    context "avatar upload" do
      let(:avatar) { fixture_file_upload("spec/fixtures/files/test_avatar.jpg", "image/jpeg") }

      it "attaches avatar to user" do
        expect {
          patch dashboard_profile_path, params: { user: { avatar: avatar } }
        }.to change { user.reload.avatar.attached? }.from(false).to(true)
      end

      it "redirects to edit profile page on success" do
        patch dashboard_profile_path, params: { user: { avatar: avatar } }
        expect(response).to redirect_to(edit_dashboard_profile_path)
        expect(flash[:notice]).to eq("Profile updated successfully.")
      end
    end

    context "avatar removal" do
      before do
        avatar = fixture_file_upload("spec/fixtures/files/test_avatar.jpg", "image/jpeg")
        user.avatar.attach(avatar)
      end

      it "removes avatar when checkbox is checked" do
        expect {
          patch dashboard_profile_path, params: { user: { avatar_remove: "true" } }
        }.to change { user.reload.avatar.attached? }.from(true).to(false)
      end
    end

    context "validation errors" do
      it "renders edit form when first name is blank" do
        patch dashboard_profile_path, params: { user: { first_name: "" } }
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("First name can&#39;t be blank")
      end

      it "renders edit form when last name is blank" do
        patch dashboard_profile_path, params: { user: { last_name: "" } }
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("Last name can&#39;t be blank")
      end

      it "renders edit form when email is taken" do
        other_user = FactoryBot.create(:user)
        patch dashboard_profile_path, params: { user: { email: other_user.email } }
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("Email has already been taken")
      end

      it "renders edit form when phone format is invalid" do
        patch dashboard_profile_path, params: { user: { phone: "not-a-phone" } }
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("Phone must be a valid phone number")
      end
    end

    context "password changes" do
      it "requires current password when changing password" do
        patch dashboard_profile_path, params: {
          user: {
            password: "newpassword123",
            password_confirmation: "newpassword123",
            current_password: ""
          }
        }
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("Current password can&#39;t be blank")
      end

      it "validates current password is correct" do
        patch dashboard_profile_path, params: {
          user: {
            password: "newpassword123",
            password_confirmation: "newpassword123",
            current_password: "wrongpassword"
          }
        }
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("Current password is invalid")
      end

      it "requires password confirmation to match" do
        patch dashboard_profile_path, params: {
          user: {
            password: "newpassword123",
            password_confirmation: "different",
            current_password: user.password
          }
        }
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("Password confirmation doesn&#39;t match")
      end

      it "enforces minimum password length" do
        patch dashboard_profile_path, params: {
          user: {
            password: "short",
            password_confirmation: "short",
            current_password: user.password
          }
        }
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("Password is too short")
      end

      it "successfully changes password with valid params" do
        patch dashboard_profile_path, params: {
          user: {
            password: "newpassword123",
            password_confirmation: "newpassword123",
            current_password: user.password
          }
        }
        expect(response).to redirect_to(edit_dashboard_profile_path)
        expect(flash[:notice]).to eq("Profile updated successfully.")

        # Verify user can sign in with new password
        user.reload
        expect(user.valid_password?("newpassword123")).to be true
      end
    end
  end
end
