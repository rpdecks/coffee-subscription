module ApplicationHelper
  include Pagy::Frontend

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

  def pagy_nav(pagy)
    html = +%(<nav class="flex items-center gap-1" aria-label="Pagination">)

    # Previous button
    if pagy.prev
      html << %(<a href="#{pagy_url_for(pagy, pagy.prev)}" class="px-3 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-md hover:bg-gray-50">Previous</a>)
    else
      html << %(<span class="px-3 py-2 text-sm font-medium text-gray-400 bg-gray-100 border border-gray-300 rounded-md cursor-not-allowed">Previous</span>)
    end

    # Page numbers
    pagy.series.each do |item|
      case item
      when Integer
        if item == pagy.page
          html << %(<span class="px-3 py-2 text-sm font-medium text-white bg-green-600 border border-green-600 rounded-md">#{item}</span>)
        else
          html << %(<a href="#{pagy_url_for(pagy, item)}" class="px-3 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-md hover:bg-gray-50">#{item}</a>)
        end
      when String
        html << %(<span class="px-3 py-2 text-sm font-medium text-gray-400">#{item}</span>)
      end
    end

    # Next button
    if pagy.next
      html << %(<a href="#{pagy_url_for(pagy, pagy.next)}" class="px-3 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-md hover:bg-gray-50">Next</a>)
    else
      html << %(<span class="px-3 py-2 text-sm font-medium text-gray-400 bg-gray-100 border border-gray-300 rounded-md cursor-not-allowed">Next</span>)
    end

    html << %(</nav>)
    html.html_safe
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
