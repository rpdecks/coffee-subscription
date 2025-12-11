require 'rails_helper'

RSpec.describe ApplicationPolicy, type: :policy do
  subject { described_class.new(user, record) }

  let(:user) { build_stubbed(:user) }
  let(:record) { double("Record") }

  describe "default permissions" do
    it "denies index" do
      expect(subject.index?).to be false
    end

    it "denies show" do
      expect(subject.show?).to be false
    end

    it "denies create" do
      expect(subject.create?).to be false
    end

    it "denies new" do
      expect(subject.new?).to be false
    end

    it "denies update" do
      expect(subject.update?).to be false
    end

    it "denies edit" do
      expect(subject.edit?).to be false
    end

    it "denies destroy" do
      expect(subject.destroy?).to be false
    end
  end

  describe "#new?" do
    it "delegates to create?" do
      allow(subject).to receive(:create?).and_return(true)
      expect(subject.new?).to be true
    end
  end

  describe "#edit?" do
    it "delegates to update?" do
      allow(subject).to receive(:update?).and_return(true)
      expect(subject.edit?).to be true
    end
  end

  describe ApplicationPolicy::Scope do
    subject { described_class.new(user, scope) }

    let(:scope) { double("Scope") }

    describe "#resolve" do
      it "raises NoMethodError" do
        expect { subject.resolve }.to raise_error(NoMethodError, /You must define #resolve/)
      end
    end
  end
end
