module AffiliateLinksHelper
  AMAZON_HOST_REGEX = /(^|\.)amazon\./i
  AMAZON_SHORT_HOST_REGEX = /(^|\.)amzn\.to$/i

  def amazon_url?(raw_url)
    return false if raw_url.blank?

    uri = URI.parse(raw_url.to_s)
    return false unless uri.is_a?(URI::HTTP)

    host = uri.host.to_s
    host.match?(AMAZON_HOST_REGEX) || host.match?(AMAZON_SHORT_HOST_REGEX)
  rescue URI::InvalidURIError
    false
  end

  def amazon_associate_tag
    ENV["AMAZON_ASSOCIATE_TAG"].presence || Rails.application.credentials.dig(:amazon, :associate_tag).presence
  end

  def amazon_affiliate_url(raw_url)
    return if raw_url.blank?

    url = raw_url.to_s

    uri = URI.parse(url)
    return url unless uri.is_a?(URI::HTTP)

    host = uri.host.to_s
    return url unless host.match?(AMAZON_HOST_REGEX)

    tag = amazon_associate_tag
    return url if tag.blank?

    existing_params = begin
      Rack::Utils.parse_nested_query(uri.query)
    rescue StandardError
      {}
    end

    return url if existing_params["tag"].present?

    merged_params = existing_params.merge("tag" => tag)
    uri.query = merged_params.to_query

    uri.to_s
  rescue URI::InvalidURIError
    raw_url
  end
end
