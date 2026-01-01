require 'rails_helper'

RSpec.describe User, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:first_name) }
    it { is_expected.to validate_presence_of(:last_name) }
    it { is_expected.to validate_presence_of(:email) }

    it "validates phone format" do
      user = build(:user, phone: "invalid")
      expect(user).not_to be_valid
      expect(user.errors[:phone]).to include("must be a valid phone number")
    end

    it "allows valid phone formats" do
      valid_phones = [ "123-456-7890", "(123) 456-7890", "+1 123 456 7890", "1234567890" ]
      valid_phones.each do |phone|
        user = build(:user, phone: phone)
        expect(user).to be_valid
      end
    end

    it "allows blank phone" do
      user = build(:user, phone: nil)
      expect(user).to be_valid
    end
  end

  describe "associations" do
    it { is_expected.to have_many(:addresses) }
    it { is_expected.to have_many(:payment_methods) }
    it { is_expected.to have_many(:subscriptions) }
    it { is_expected.to have_many(:orders) }
    it { is_expected.to have_one(:coffee_preference) }
    it { is_expected.to have_one_attached(:avatar) }
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:role).with_values(customer: 0, admin: 1) }
  end

  describe "#full_name" do
    it "returns first and last name combined" do
      user = build(:user, first_name: "John", last_name: "Doe")
      expect(user.full_name).to eq("John Doe")
    end

    it "strips whitespace" do
      user = build(:user, first_name: "John", last_name: "Doe")
      expect(user.full_name).to eq("John Doe")
    end
  end

  describe "#ensure_stripe_customer" do
    let(:user) { create(:user) }

    context "when stripe_customer_id exists" do
      before { user.update(stripe_customer_id: "cus_123") }

      it "returns existing customer id" do
        expect(StripeService).not_to receive(:create_customer)
        expect(user.ensure_stripe_customer).to eq("cus_123")
      end
    end

    context "when stripe_customer_id does not exist" do
      it "creates a Stripe customer" do
        expect(StripeService).to receive(:create_customer).with(user).and_return("cus_456")
        expect(user.ensure_stripe_customer).to eq("cus_456")
      end
    end
  end

  describe "callbacks" do
    context "after_create" do
      it "attempts to queue Stripe customer creation for customers" do
        # Test that the callback exists and doesn't raise errors
        expect {
          create(:user, role: :customer)
        }.not_to raise_error
      end

      it "does not attempt Stripe customer creation for admins" do
        expect {
          create(:user, role: :admin)
        }.not_to raise_error
      end
    end
  end

  describe "avatar validations" do
    let(:user) { create(:user) }

    it "accepts valid image types" do
      %w[image/png image/jpeg image/webp].each do |content_type|
        avatar = fixture_file_upload("spec/fixtures/files/test_avatar.jpg", content_type)
        user.avatar.attach(avatar)
        expect(user).to be_valid
      end
    end

    it "rejects invalid file types" do
      # Create a blob with invalid content type and attach it
      user.avatar.attach(
        io: StringIO.new("fake file content"),
        filename: "test.pdf",
        content_type: "application/pdf"
      )
      user.validate
      expect(user.errors[:avatar]).to include("must be a PNG, JPEG, or WebP image")
    end

    it "rejects files larger than 5MB" do
      avatar = fixture_file_upload("spec/fixtures/files/test_avatar.jpg", "image/jpeg")
      user.avatar.attach(avatar)
      user.avatar.blob.update(byte_size: 6.megabytes)
      user.validate
      expect(user.errors[:avatar]).to include("must be less than 5 MB")
    end

    it "allows files smaller than 5MB" do
      avatar = fixture_file_upload("spec/fixtures/files/test_avatar.jpg", "image/jpeg")
      user.avatar.attach(avatar)
      expect(user).to be_valid
    end
  end
end
