# frozen_string_literal: true

class ProductDraftCreator
  Result = Struct.new(:success?, :product, :errors, keyword_init: true)

  ATTRIBUTES = %i[
    name
    description
    product_type
    roast_type
    price
    weight_oz
    inventory_count
    active
    visible_in_shop
    stripe_product_id
    stripe_price_id
  ].freeze

  def self.call(params:)
    new(params:).call
  end

  def initialize(params:)
    @params = params.to_h.deep_symbolize_keys
  end

  def call
    product = Product.new(normalized_attributes)

    if product.save
      Result.new(success?: true, product: product, errors: [])
    else
      Result.new(success?: false, product: product, errors: product.errors.full_messages)
    end
  rescue StandardError => error
    Result.new(success?: false, product: nil, errors: [ error.message ])
  end

  private

  attr_reader :params

  def normalized_attributes
    attributes = params.slice(*ATTRIBUTES)

    attributes[:name] = clean_string(attributes[:name])
    attributes[:description] = clean_string(attributes[:description])
    attributes[:product_type] = clean_string(attributes[:product_type])
    attributes[:roast_type] = clean_string(attributes[:roast_type])
    attributes[:stripe_product_id] = clean_string(attributes[:stripe_product_id])
    attributes[:stripe_price_id] = clean_string(attributes[:stripe_price_id])
    attributes[:weight_oz] = normalize_number(attributes[:weight_oz])
    attributes[:inventory_count] = normalize_integer(attributes[:inventory_count])
    attributes[:price] = normalize_number(attributes[:price])
    attributes[:roast_type] = nil if attributes[:product_type] == "merch"

    attributes.compact
  end

  def clean_string(value)
    value.to_s.strip.presence
  end

  def normalize_number(value)
    return nil if value.nil? || value == ""

    BigDecimal(value.to_s)
  end

  def normalize_integer(value)
    return nil if value.nil? || value == ""

    Integer(value)
  end
end
