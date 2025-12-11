require 'rails_helper'

RSpec.describe Address, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:street_address) }
    it { is_expected.to validate_presence_of(:city) }
    it { is_expected.to validate_presence_of(:state) }
    it { is_expected.to validate_presence_of(:zip_code) }
    it { is_expected.to validate_presence_of(:country) }
    it { is_expected.to validate_presence_of(:address_type) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:user) }
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:address_type).with_values(
      shipping: 0, billing: 1
    ) }
  end

  describe "scopes" do
    let(:user) { create(:user) }
    let!(:default_shipping) { create(:address, user: user, is_default: true, address_type: :shipping) }
    let!(:non_default_shipping) { create(:address, user: user, is_default: false, address_type: :shipping) }
    let!(:shipping_address) { create(:address, user: create(:user), address_type: :shipping) }
    let!(:billing_address) { create(:address, user: create(:user), address_type: :billing) }

    describe ".default" do
      it "returns only default addresses" do
        defaults = Address.default.where(user: user)
        expect(defaults).to include(default_shipping)
        expect(defaults).not_to include(non_default_shipping)
      end
    end

    describe ".shipping" do
      it "returns only shipping addresses" do
        expect(Address.shipping).to include(shipping_address, default_shipping, non_default_shipping)
        expect(Address.shipping).not_to include(billing_address)
      end
    end

    describe ".billing" do
      it "returns only billing addresses" do
        expect(Address.billing).to include(billing_address)
        expect(Address.billing).not_to include(shipping_address)
      end
    end
  end

  describe "#full_address" do
    it "formats address with all fields" do
      address = build(:address,
        street_address: "123 Main St",
        street_address_2: "Apt 4B",
        city: "Portland",
        state: "OR",
        zip_code: "97201",
        country: "USA"
      )
      expected = "123 Main St\nApt 4B\nPortland, OR 97201\nUSA"
      expect(address.full_address).to eq(expected)
    end

    it "formats address without street_address_2" do
      address = build(:address,
        street_address: "123 Main St",
        street_address_2: nil,
        city: "Portland",
        state: "OR",
        zip_code: "97201",
        country: "USA"
      )
      expected = "123 Main St\nPortland, OR 97201\nUSA"
      expect(address.full_address).to eq(expected)
    end
  end

  describe "callbacks" do
    let(:user) { create(:user) }

    describe "set_default_if_first" do
      it "sets first shipping address as default" do
        address = create(:address, user: user, address_type: :shipping, is_default: false)
        expect(address.reload.is_default).to be true
      end

      it "does not set as default if another shipping address exists" do
        create(:address, user: user, address_type: :shipping, is_default: true)
        address = create(:address, user: user, address_type: :shipping, is_default: false)
        expect(address.reload.is_default).to be false
      end

      it "allows separate defaults for shipping and billing" do
        shipping = create(:address, user: user, address_type: :shipping)
        billing = create(:address, user: user, address_type: :billing)
        expect(shipping.is_default).to be true
        expect(billing.is_default).to be true
      end
    end

    describe "ensure_only_one_default" do
      it "unsets other default addresses of same type" do
        old_default = create(:address, user: user, address_type: :shipping, is_default: true)
        new_default = create(:address, user: user, address_type: :shipping, is_default: true)

        expect(old_default.reload.is_default).to be false
        expect(new_default.reload.is_default).to be true
      end

      it "does not affect default addresses of different type" do
        shipping_default = create(:address, user: user, address_type: :shipping, is_default: true)
        billing_default = create(:address, user: user, address_type: :billing, is_default: true)

        expect(shipping_default.reload.is_default).to be true
        expect(billing_default.reload.is_default).to be true
      end
    end
  end
end
