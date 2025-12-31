require "rails_helper"

RSpec.describe SidekiqSmokeTestJob, type: :job do
  describe "#perform" do
    it "logs start and done" do
      token = "test-token"

      logger = instance_double(Logger)
      allow(Rails).to receive(:logger).and_return(logger)

      expect(logger).to receive(:info).with("[SidekiqSmokeTestJob] start token=#{token}")
      expect(logger).to receive(:info).with("[SidekiqSmokeTestJob] done token=#{token}")

      described_class.perform_now(token)
    end
  end
end
