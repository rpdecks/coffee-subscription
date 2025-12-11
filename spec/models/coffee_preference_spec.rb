require 'rails_helper'

RSpec.describe CoffeePreference, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:roast_level) }
    it { is_expected.to validate_presence_of(:grind_type) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:user) }
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:roast_level).with_values(
      light: 0, medium_roast: 1, dark: 2, variety: 3
    ) }

    it { is_expected.to define_enum_for(:grind_type).with_values(
      whole_bean: 0, coarse: 1, medium_grind: 2, fine: 3, espresso: 4
    ) }
  end

  describe "enum queries" do
    let(:user) { create(:user) }
    let(:preference) { create(:coffee_preference, user: user, roast_level: :medium_roast, grind_type: :coarse) }

    it "allows querying by roast_level" do
      expect(preference.medium_roast?).to be true
      expect(preference.light?).to be false
    end

    it "allows querying by grind_type" do
      expect(preference.coarse?).to be true
      expect(preference.whole_bean?).to be false
    end
  end
end
