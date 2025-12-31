class SidekiqSmokeTestJob < ApplicationJob
  queue_as :default

  def perform(token = nil)
    token ||= SecureRandom.hex(8)

    Rails.logger.info("[SidekiqSmokeTestJob] start token=#{token}")
    Rails.logger.info("[SidekiqSmokeTestJob] done token=#{token}")
  end
end
