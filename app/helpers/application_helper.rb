module ApplicationHelper
  def nav_link_html_options(path, variant: :desktop, class_name: nil)
    active = nav_active_for?(path)

    classes = [
      "nav-link",
      (variant.to_sym == :mobile ? "nav-link--mobile" : "nav-link--desktop"),
      (active ? "nav-link--active" : nil),
      class_name
    ].compact.join(" ")

    options = { class: classes }
    options[:aria] = { current: "page" } if active
    options
  end

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

    svg_content = svg_content.sub(/\A<\?xml[^>]*\?>\s*/m, "")

    if options.present?
      svg_content = svg_content.sub(/<svg\b[^>]*>/) do |svg_tag|
        tag = svg_tag.dup

        if options[:class].present?
          escaped_class = ERB::Util.html_escape(options[:class].to_s)
          if tag.match?(/\bclass=\"/)
            tag.sub!(/\bclass=\"([^\"]*)\"/) { %(class="#{$1} #{escaped_class}") }
          else
            tag.sub!("<svg", "<svg class=\"#{escaped_class}\"")
          end
        end

        if options[:style].present?
          escaped_style = ERB::Util.html_escape(options[:style].to_s)
          if tag.match?(/\bstyle=\"/)
            tag.sub!(/\bstyle=\"([^\"]*)\"/) { %(style="#{$1}; #{escaped_style}") }
          else
            tag.sub!("<svg", "<svg style=\"#{escaped_style}\"")
          end
        end

        if options[:width].present? && !tag.match?(/\bwidth=\"/)
          tag.sub!("<svg", "<svg width=\"#{ERB::Util.html_escape(options[:width].to_s)}\"")
        end

        if options[:height].present? && !tag.match?(/\bheight=\"/)
          tag.sub!("<svg", "<svg height=\"#{ERB::Util.html_escape(options[:height].to_s)}\"")
        end

        if options[:aria_label].present?
          escaped_label = ERB::Util.html_escape(options[:aria_label].to_s)
          tag.sub!("<svg", "<svg aria-label=\"#{escaped_label}\" role=\"img\"")
        end

        tag
      end
    end

    svg_content.html_safe
  end

  private

  def nav_active_for?(path)
    target_path = path.to_s
    current = request&.path.to_s

    current == target_path || current.start_with?("#{target_path}/")
  end

  def nav_link_base_classes(variant)
    case variant.to_sym
    when :mobile
      "block"
    else
      ""
    end
  end

  def nav_link_inactive_classes(variant)
    case variant.to_sym
    when :mobile
      ""
    else
      ""
    end
  end

  def nav_link_active_classes(variant)
    case variant.to_sym
    when :mobile
      ""
    else
      ""
    end
  end
end
