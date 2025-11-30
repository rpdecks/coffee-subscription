class Rack::Attack
  # Throttle contact form submissions by IP address
  throttle('contact_form/ip', limit: 3, period: 1.hour) do |req|
    if req.path == '/contact' && req.post?
      req.ip
    end
  end

  # Throttle general POST requests by IP
  throttle('req/ip', limit: 300, period: 5.minutes) do |req|
    req.ip if req.post?
  end

  # Block requests from known bad actors
  blocklist('block bad IPs') do |req|
    # Add IPs to block here if needed
    # Example: ['1.2.3.4', '5.6.7.8'].include?(req.ip)
    false
  end

  # Custom response for throttled requests
  self.throttled_responder = lambda do |req|
    match_data = req.env['rack.attack.match_data']
    now = match_data[:epoch_time]

    headers = {
      'RateLimit-Limit' => match_data[:limit].to_s,
      'RateLimit-Remaining' => '0',
      'RateLimit-Reset' => (now + (match_data[:period] - now % match_data[:period])).to_s
    }

    [429, headers, ["Too many requests. Please try again later.\n"]]
  end
end
