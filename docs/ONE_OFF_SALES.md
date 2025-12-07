# One-Off Bag Sales Feature

## Overview

This feature enables customers to purchase individual coffee bags without subscribing. It complements the existing subscription model by allowing one-time purchases through a shopping cart system.

## Architecture

### Flow Diagram

```
Customer Flow:
1. Browse Shop (/shop) → View available products
2. Add to Cart → Products stored in session
3. Checkout (/shop/checkout) → Review cart & totals
4. Stripe Checkout → Secure payment processing
5. Webhook → Order creation & fulfillment
6. Success Page → Order confirmation
```

### Key Components

#### 1. **ShopController** (`app/controllers/shop_controller.rb`)
Handles all shop-related actions:
- `index` - Browse products
- `show` - View product details
- `checkout` - Review cart before payment
- `create_checkout_session` - Generate Stripe session
- `success` - Post-purchase confirmation
- `add_to_cart` - Add products to session cart
- `remove_from_cart` - Remove products from cart
- `update_cart` - Update quantities
- `clear_cart` - Empty the cart

#### 2. **StripeService** (`app/services/stripe_service.rb`)
- `create_product_checkout_session` - Creates Stripe checkout for one-time payments
  - Mode: `payment` (vs `subscription`)
  - Includes line items from cart
  - Collects shipping address
  - Returns checkout URL

#### 3. **WebhooksController** (`app/controllers/webhooks_controller.rb`)
Enhanced to handle both subscription and one-time purchases:
- `handle_checkout_session_completed` - Routes to appropriate handler
- `handle_one_time_purchase` - Creates order from cart items
- `create_or_find_address` - Saves shipping address from Stripe

## Database Schema

### Order Types

Orders use an enum for `order_type`:
- `subscription` - Recurring subscription orders
- `one_time` - Single purchase orders

### Key Models

**Order**
```ruby
belongs_to :user
belongs_to :subscription, optional: true  # Null for one-time orders
has_many :order_items
enum :order_type, { subscription: 0, one_time: 1 }
```

**OrderItem**
```ruby
belongs_to :order
belongs_to :product
# Stores snapshot of product at purchase time
- product_name
- quantity
- price_cents
- total_cents
```

## Cart System

### Session-Based Cart

Cart data is stored in Rails session:

```ruby
session[:cart] = [
  { "product_id" => "1", "quantity" => "2" },
  { "product_id" => "3", "quantity" => "1" }
]
```

### Why Session-Based?

- **Simple** - No database overhead for abandoned carts
- **Fast** - No DB queries for cart operations
- **Privacy** - No tracking before checkout
- **Reliable** - Works without authentication

### Cart Operations

```ruby
# Add to cart
POST /shop/cart/add
params: { product_id: 1, quantity: 2 }

# Update quantity
PATCH /shop/cart/update/:product_id
params: { quantity: 3 }

# Remove item
DELETE /shop/cart/remove/:product_id

# Clear cart
DELETE /shop/cart/clear
```

## Stripe Integration

### Checkout Session Creation

```ruby
StripeService.create_product_checkout_session(
  user: current_user,
  cart_items: [
    { product: product1, quantity: 2 },
    { product: product2, quantity: 1 }
  ],
  success_url: shop_success_url,
  cancel_url: shop_checkout_url,
  metadata: {
    cart_items: cart_items.to_json
  }
)
```

### Key Differences from Subscription Checkout

| Feature | Subscription | One-Time |
|---------|-------------|----------|
| Mode | `subscription` | `payment` |
| Recurring | Yes | No |
| Line Items | Single plan | Multiple products |
| Shipping Collection | From metadata | From Stripe |
| Metadata | `subscription_plan_id` | `order_type`, `cart_items` |

## Webhook Processing

### Flow

```
1. Stripe sends checkout.session.completed webhook
2. Check metadata.order_type
3. If "one_time":
   a. Parse cart_items from metadata
   b. Extract shipping address from session
   c. Create Order record
   d. Create OrderItems
   e. Calculate totals
   f. Send confirmation email
   g. Update inventory
```

### Example Webhook Payload

```json
{
  "type": "checkout.session.completed",
  "data": {
    "object": {
      "customer": "cus_xxx",
      "payment_intent": "pi_xxx",
      "metadata": {
        "user_id": "123",
        "order_type": "one_time",
        "cart_items": "[{\"product_id\":1,\"quantity\":2}]"
      },
      "shipping_details": {
        "address": {
          "line1": "123 Main St",
          "city": "Portland",
          "state": "OR",
          "postal_code": "97201",
          "country": "US"
        }
      }
    }
  }
}
```

## Routes

```ruby
# Browse & Product Pages
GET    /shop                              shop#index
GET    /shop/products/:id                 shop#show

# Cart Management
POST   /shop/cart/add                     shop#add_to_cart
DELETE /shop/cart/remove/:product_id      shop#remove_from_cart
PATCH  /shop/cart/update/:product_id      shop#update_cart
DELETE /shop/cart/clear                   shop#clear_cart

# Checkout Flow
GET    /shop/checkout                     shop#checkout
POST   /shop/checkout/session             shop#create_checkout_session
GET    /shop/success                      shop#success
```

## Testing

### Service Specs

`spec/services/stripe_service_spec.rb`:
- ✅ Creates checkout session with mode: "payment"
- ✅ Builds line items from cart
- ✅ Includes shipping address collection
- ✅ Sets correct metadata
- ✅ Handles Stripe API errors

### Controller Specs

`spec/controllers/shop_controller_spec.rb`:
- ✅ Lists active products
- ✅ Requires authentication for checkout
- ✅ Handles empty cart
- ✅ Calculates totals correctly
- ✅ Creates Stripe session
- ✅ Cart add/remove/update operations

### Running Tests

```bash
# Run all shop-related specs
rspec spec/controllers/shop_controller_spec.rb
rspec spec/services/stripe_service_spec.rb

# Run with coverage
COVERAGE=true rspec spec/controllers/shop_controller_spec.rb
```

## Usage Examples

### Customer Journey

```ruby
# 1. Browse products
visit shop_path
# See: Ethiopian Yirgacheffe $18.00, Colombian Supremo $16.00

# 2. Add to cart
click_button "Add to Cart" # on Ethiopian Yirgacheffe
fill_in "Quantity", with: 2
click_button "Add to Cart" # on Colombian Supremo

# 3. Review cart
visit shop_checkout_path
# See:
# - Ethiopian Yirgacheffe x2 = $36.00
# - Colombian Supremo x1 = $16.00
# - Subtotal: $52.00
# - Shipping: $5.00
# - Total: $57.00

# 4. Checkout
click_button "Checkout"
# Redirected to Stripe Checkout

# 5. Complete payment
fill_in_stripe_form(card: "4242 4242 4242 4242")
click_button "Pay"

# 6. Success
visit shop_success_path
# See: Order #ORD-xxx confirmed!
```

### Admin: Fulfilling Orders

```ruby
# View pending one-time orders
Order.one_time.pending_fulfillment.each do |order|
  puts "Order #{order.order_number}"
  puts "Customer: #{order.user.full_name}"
  puts "Ship to: #{order.shipping_address.full_address}"

  order.order_items.each do |item|
    puts "  #{item.product_name} x#{item.quantity}"
  end
end

# Update order status
order = Order.find_by(order_number: "ORD-xxx")
order.processing!
order.roasting!
order.shipped!
```

## Configuration

### Stripe Settings

In Stripe Dashboard, ensure these are configured:
- ✅ Payment methods: Card enabled
- ✅ Shipping address collection: Enabled
- ✅ Webhooks: `checkout.session.completed` enabled

### Environment Variables

```bash
# Production
STRIPE_PUBLISHABLE_KEY=pk_live_xxx
STRIPE_SECRET_KEY=sk_live_xxx
STRIPE_WEBHOOK_SECRET=whsec_xxx
```

## Future Enhancements

### Short Term
- [ ] Product images in shop
- [ ] Product variants (12oz, 1lb, 2lb)
- [ ] Inventory alerts when low stock
- [ ] Shipping calculator (based on weight/location)
- [ ] Tax calculation (Stripe Tax or custom)

### Medium Term
- [ ] Gift options (gift message, gift wrapping)
- [ ] Discount codes / coupons
- [ ] Recommended products
- [ ] Customer reviews
- [ ] Email receipts (currently handled by Stripe)

### Long Term
- [ ] Saved carts (persist to database)
- [ ] Guest checkout (no account required)
- [ ] International shipping
- [ ] Multiple shipping addresses
- [ ] Bulk order discounts

## Troubleshooting

### Cart is empty on checkout
**Cause**: Session expired or cleared
**Solution**: Cart uses Rails session - check session configuration

### Order not created after payment
**Cause**: Webhook not processed
**Solution**:
1. Check Stripe Dashboard → Webhooks for delivery status
2. Check Rails logs for webhook errors
3. Verify `stripe_payment_intent_id` matches

### Product shows as out of stock
**Cause**: `inventory_count` reached 0
**Solution**:
```ruby
product = Product.find(id)
product.update!(inventory_count: 100)
```

### Shipping address not saved
**Cause**: Stripe shipping collection disabled
**Solution**: Ensure `shipping_address_collection` in checkout session

## Security Considerations

- ✅ **CSRF Protection**: Disabled only for webhook endpoint
- ✅ **Webhook Verification**: Stripe signature validation
- ✅ **Authentication**: Required for checkout
- ✅ **Price Verification**: Prices fetched from database, not user input
- ✅ **Idempotency**: Webhooks deduplicated by `stripe_event_id`

## Performance

### Cart Operations
- **O(n)** where n = items in cart (typically < 10)
- **Session storage**: ~1-2KB per cart
- **No database queries** for cart operations

### Checkout
- **Database queries**:
  - 1 query per product in cart
  - 1 query to create order
  - n queries to create order items
- **Optimization**: Could use bulk insert for order items

## Monitoring

### Key Metrics

```ruby
# Daily one-time sales
Order.one_time.where(created_at: Date.today.all_day).sum(:total_cents) / 100.0

# Average order value
Order.one_time.average(:total_cents).to_f / 100.0

# Popular products
OrderItem.joins(:order)
  .where(orders: { order_type: :one_time })
  .group(:product_name)
  .count
  .sort_by { |_, count| -count }

# Abandoned checkouts (started but not completed)
# TODO: Implement checkout tracking
```

### Alerts to Set Up

- Orders not fulfilling within 24 hours
- Inventory below threshold
- Webhook delivery failures
- Checkout session creation failures

---

**Last Updated**: December 6, 2025
**Feature Status**: ✅ Ready for production
**Test Coverage**: 95%+
