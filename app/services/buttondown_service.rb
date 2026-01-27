require "json"
require "net/http"
require "uri"

class ButtondownService
  API_BASE = "https://api.buttondown.email/v1".freeze

  def self.configured?
    api_key.present?
  end

  def self.subscribe(email:)
    key = api_key
    return false if key.blank?

    uri = URI.join(API_BASE + "/", "subscribers")

    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Token #{key}"
    request["Content-Type"] = "application/json"
    request.body = { email_address: email }.to_json

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 5
    http.read_timeout = 10

    response = http.request(request)

    case response
    when Net::HTTPSuccess
      true
    when Net::HTTPClientError
      # Treat "already subscribed"-style responses as success.
      # Buttondown's API error messages can vary; be permissive.
      body = response.body.to_s

      begin
        json = JSON.parse(body)
        code = json["code"].to_s
        return true if code.match?(/already/i)
        return false if code == "subscriber_blocked"
      rescue JSON::ParserError
        # ignore
      end

      return true if response.code.to_s == "409"
      return true if body.match?(/already\s+subscribed/i)
      Rails.logger.warn("Buttondown subscribe failed (#{response.code}): #{body.tr("\n", " ").first(500)}")
      false
    else
      Rails.logger.warn("Buttondown subscribe failed (#{response.code}): #{response.body.to_s.tr("\n", " ").first(500)}")
      false
    end
  rescue => e
    Rails.logger.error("Buttondown subscribe error: #{e.class}: #{e.message}")
    false
  end

  def self.api_key
    ENV["BUTTONDOWN_API_KEY"].presence || Rails.application.credentials.dig(:buttondown, :api_key)
  end
end
