require 'ostruct'

# Override Pagy::Backend#pagy for controller specs
# This provides a simple implementation that works with our test setup
module PagyTestOverride
  def pagy(collection, vars = {})
    items_per_page = vars[:items] || 25
    page = vars[:page] || 1

    # Get total count
    total_count = collection.is_a?(ActiveRecord::Relation) ? collection.count : collection.size
    total_pages = (total_count.to_f / items_per_page).ceil
    total_pages = 1 if total_pages.zero?

    # Create pagy object
    pagy_vars = { page: page, items: items_per_page, page_param: :page, size: 7, params: {} }.merge(vars)

    pagy_obj = OpenStruct.new(
      page: page,
      pages: total_pages,
      count: total_count,
      items: items_per_page,
      vars: pagy_vars
    )

    pagy_obj.define_singleton_method(:from) do
      return 0 if total_count.zero?
      ((page - 1) * items_per_page) + 1
    end

    pagy_obj.define_singleton_method(:to) do
      [ page * items_per_page, total_count ].min
    end

    pagy_obj.define_singleton_method(:prev) do
      page > 1 ? page - 1 : nil
    end

    pagy_obj.define_singleton_method(:next) do
      page < total_pages ? page + 1 : nil
    end

    pagy_obj.define_singleton_method(:label_for) do |value|
      value.to_s
    end

    pagy_obj.define_singleton_method(:series) do |**|
      [].tap do |series|
        1.upto(total_pages) do |number|
          series << (number == page ? number.to_s : number)
        end
      end
    end

    # Paginate collection - must preserve order!
    paginated = if collection.is_a?(ActiveRecord::Relation)
      # Preserve the existing order from the collection
      collection.limit(items_per_page).offset((page - 1) * items_per_page).to_a
    else
      collection.drop((page - 1) * items_per_page).take(items_per_page)
    end

    [ pagy_obj, paginated ]
  end
end

# Prepend to all controllers that include Pagy::Backend
ApplicationController.prepend(PagyTestOverride)

# Provide pagy_nav helper in views during tests
module PagyTestFrontendOverride
  def pagy_nav(pagy, **)
    return "" unless pagy

    html = +""
    if pagy.pages > 1
      html << '<nav class="pagination" aria-label="Pagination">'
      1.upto(pagy.pages) do |page|
        if page == pagy.page
          html << %(<span class="current">#{page}</span> )
        else
          html << %(<a href="?page=#{page}">#{page}</a> )
        end
      end
      html << "</nav>"
    end
    html.html_safe
  end
end

ActionView::Base.prepend(PagyTestFrontendOverride)
