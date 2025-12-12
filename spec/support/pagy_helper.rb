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
    pagy_obj = OpenStruct.new(
      page: page,
      pages: total_pages,
      count: total_count,
      items: items_per_page,
      vars: vars
    )

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
