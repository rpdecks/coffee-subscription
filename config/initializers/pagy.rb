# Pagy Configuration
require 'pagy/extras/overflow'

Pagy::DEFAULT[:items] = 25
Pagy::DEFAULT[:overflow] = :last_page

# Tailwind CSS styling for pagination
Pagy::Frontend.module_eval do
  def pagy_nav(pagy, pagy_id: nil, link_extra: '', **vars)
    html = +%(<nav class="flex items-center gap-1" #{'id="#{pagy_id}" ' if pagy_id}aria-label="Pagination">)

    # Previous button
    if pagy.prev
      html << %(<a href="#{pagy_url_for(pagy, pagy.prev)}" class="px-3 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-md hover:bg-gray-50" rel="prev" aria-label="previous">Previous</a>)
    else
      html << %(<span class="px-3 py-2 text-sm font-medium text-gray-400 bg-gray-100 border border-gray-300 rounded-md cursor-not-allowed">Previous</span>)
    end

    # Page numbers
    pagy.series.each do |item|
      case item
      when Integer
        if item == pagy.page
          html << %(<span class="px-3 py-2 text-sm font-medium text-white bg-blue-600 border border-blue-600 rounded-md">#{item}</span>)
        else
          html << %(<a href="#{pagy_url_for(pagy, item)}" class="px-3 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-md hover:bg-gray-50">#{item}</a>)
        end
      when String
        html << %(<span class="px-3 py-2 text-sm font-medium text-gray-400">#{item}</span>)
      end
    end

    # Next button
    if pagy.next
      html << %(<a href="#{pagy_url_for(pagy, pagy.next)}" class="px-3 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-md hover:bg-gray-50" rel="next" aria-label="next">Next</a>)
    else
      html << %(<span class="px-3 py-2 text-sm font-medium text-gray-400 bg-gray-100 border border-gray-300 rounded-md cursor-not-allowed">Next</span>)
    end

    html << %(</nav>)
  end
end
