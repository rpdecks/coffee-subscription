class Rack::Attack
  # Always allow requests from localhost
  safelist("allow from localhost") do |req|
    req.ip == "127.0.0.1" || req.ip == "::1"
  end

  # Throttle login attempts by IP address
  throttle("logins/ip", limit: 5, period: 20.minutes) do |req|
    if req.path == "/users/sign_in" && req.post?
      req.ip
    end
  end

  # Throttle login attempts by email address
  throttle("logins/email", limit: 5, period: 20.minutes) do |req|
    if req.path == "/users/sign_in" && req.post?
      req.params["user"]&.[]("email").to_s.downcase.presence
    end
  end

  # Throttle signup attempts by IP
  throttle("signups/ip", limit: 3, period: 1.hour) do |req|
    if req.path == "/users" && req.post?
      req.ip
    end
  end

  # Throttle password reset requests by IP
  throttle("password_resets/ip", limit: 3, period: 20.minutes) do |req|
    if req.path == "/users/password" && req.post?
      req.ip
    end
  end

  # Throttle contact form submissions by IP address
  throttle("contact_form/ip", limit: 3, period: 1.hour) do |req|
    if req.path == "/contact" && req.post?
      req.ip
    end
  end

  # Throttle API/checkout endpoints more aggressively
  throttle("api/ip", limit: 10, period: 1.minute) do |req|
    if req.path.start_with?("/webhooks/", "/checkout/")
      req.ip
    end
  end

  # Throttle general POST requests by IP
  throttle("req/ip", limit: 300, period: 5.minutes) do |req|
    req.ip if req.post?
  end

  # Block suspicious user agents (bots, scrapers)
  blocklist("block bad user agents") do |req|
    suspicious_agents = [
      /python-requests/i,
      /curl/i,
      /wget/i,
      /scrapy/i,
      /bot/i,
      /crawl/i,
      /spider/i
    ]

    user_agent = req.user_agent.to_s
    # Allow legitimate bots (Google, Bing, etc.)
    is_legitimate = user_agent.match?(/googlebot|bingbot|yandexbot/i)

    !is_legitimate && suspicious_agents.any? { |pattern| user_agent.match?(pattern) }
  end

  # Block requests from known bad actors (add IPs as needed)
  blocklist("block bad IPs") do |req|
    # Add IPs to block here if needed
    # Example: ['1.2.3.4', '5.6.7.8'].include?(req.ip)
    false
  end

  # Custom response for throttled requests
  self.throttled_responder = lambda do |req|
    match_data = req.env["rack.attack.match_data"]
    now = match_data[:epoch_time]

    headers = {
      "RateLimit-Limit" => match_data[:limit].to_s,
      "RateLimit-Remaining" => "0",
      "RateLimit-Reset" => (now + (match_data[:period] - now % match_data[:period])).to_s,
      "Retry-After" => (match_data[:period] - now % match_data[:period]).to_s
    }

    [ 429, headers, [ "Too many requests. Please try again later.\n" ] ]
  end

  # Custom response for blocked requests
  self.blocklisted_responder = lambda do |_req|
    [ 403, { "Content-Type" => "text/plain" }, [ "Forbidden\n" ] ]
  end
end
