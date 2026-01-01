module ApplicationHelper
  def format_ounces(ounces)
    return if ounces.blank?

    formatted = number_with_precision(
      ounces,
      precision: 2,
      strip_insignificant_zeros: true
    )

    "#{formatted} oz"
  end

  def ounces_field_value(ounces)
    return if ounces.blank?

    value = ounces.to_f
    (value % 1).zero? ? value.to_i : value
  end

  def status_color_class(status)
    case status.to_s
    when "active"
      "bg-green-100 text-green-800"
    when "paused"
      "bg-yellow-100 text-yellow-800"
    when "cancelled", "expired"
      "bg-gray-100 text-gray-800"
    when "past_due"
      "bg-red-100 text-red-800"
    else
      "bg-gray-100 text-gray-800"
    end
  end

  def inline_svg(path, options = {})
    file_path = Rails.root.join("app", "assets", "images", path)
    return unless File.exist?(file_path)

    svg_content = File.read(file_path)

    # Add CSS classes if provided
    if options[:class]
      svg_content.sub("<svg", "<svg class=\"#{options[:class]}\"")
    else
      svg_content
    end.html_safe
  end
end
