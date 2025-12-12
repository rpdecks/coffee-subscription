module Admin::InventoryHelper
  def inventory_state_badge(state)
    colors = {
      "green" => "bg-green-100 text-green-800",
      "roasted" => "bg-amber-100 text-amber-800",
      "packaged" => "bg-blue-100 text-blue-800"
    }

    content_tag :span, state.titleize, class: "px-2 py-1 inline-flex text-xs font-semibold rounded-full #{colors[state]}"
  end

  def inventory_freshness_badge(item)
    return content_tag(:span, "—", class: "text-sm text-gray-500") unless item.roasted_on && item.product.coffee?

    days = item.days_since_roast
    if days <= 7
      content_tag :span, "Fresh (#{days}d)", class: "px-2 py-1 inline-flex text-xs font-semibold rounded-full bg-green-100 text-green-800"
    elsif days <= 21
      content_tag :span, "Good (#{days}d)", class: "px-2 py-1 inline-flex text-xs font-semibold rounded-full bg-yellow-100 text-yellow-800"
    else
      content_tag :span, "Aging (#{days}d)", class: "px-2 py-1 inline-flex text-xs font-semibold rounded-full bg-gray-100 text-gray-800"
    end
  end

  def inventory_quantity_status(quantity)
    if quantity == 0
      content_tag(:div, "Out of Stock", class: "text-xs text-red-600")
    elsif quantity <= 5
      content_tag(:div, "Low Stock", class: "text-xs text-yellow-600")
    end
  end
end
