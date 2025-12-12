class ProductionPlanService
  PlanEntry = Struct.new(:product, :demand, :available, :to_roast) do
    def deficit?
      to_roast.positive?
    end
  end

  Result = Struct.new(:reference_date, :generated_at, :orders_count, :plan_entries)

  def self.call(reference_date: Date.today)
    new(reference_date: reference_date).call
  end

  def initialize(reference_date: Date.today)
    @reference_date = reference_date
  end

  def call
    rows = demand_by_product.map do |product, demand|
      available = product&.total_roasted_inventory || 0.0
      to_roast = [demand - available, 0.0].max
      PlanEntry.new(product, demand, available, to_roast)
    end

    Result.new(
      reference_date,
      Time.current,
      eligible_orders.count,
      rows.sort_by { |entry| -entry.to_roast }
    )
  end

  private

  attr_reader :reference_date

  def eligible_orders
    @eligible_orders ||= Order.pending_fulfillment.includes(order_items: :product)
  end

  def demand_by_product
    eligible_orders.flat_map(&:order_items)
                   .compact
                   .select { |item| item.product.present? }
                   .group_by(&:product)
                   .transform_values { |items| items.sum(&:quantity) }
  end
end
