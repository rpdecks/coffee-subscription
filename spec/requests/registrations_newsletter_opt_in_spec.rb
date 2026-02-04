require "rails_helper"

RSpec.describe "Registration newsletter opt-in", type: :request do
  it "subscribes the user when opted in" do
    allow(ButtondownService).to receive(:configured?).and_return(true)
    expect(ButtondownService).to receive(:subscribe).with(email: "newuser@example.com").and_return(true)

    post user_registration_path, params: {
      user: {
        first_name: "New",
        last_name: "User",
        email: "newuser@example.com",
        password: "password123",
        password_confirmation: "password123",
        newsletter_opt_in: "1"
      }
    }

    expect(User.find_by(email: "newuser@example.com")).to be_present
  end

  it "does not subscribe when not opted in" do
    allow(ButtondownService).to receive(:configured?).and_return(true)
    expect(ButtondownService).not_to receive(:subscribe)

    post user_registration_path, params: {
      user: {
        first_name: "New",
        last_name: "User",
        email: "nooptin@example.com",
        password: "password123",
        password_confirmation: "password123"
      }
    }

    expect(User.find_by(email: "nooptin@example.com")).to be_present
  end
end
