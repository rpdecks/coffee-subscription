# Stripe Products Setup Guide

## For Mirrored Test & Production Environments

### Step 1: Create Products in Stripe Dashboard

Go to: **Products** → **Add Product** in BOTH Test mode and Live mode

### Subscription Products

Create these for your subscription plans:

**1. Monthly Subscription**

- Name: `Monthly Coffee Subscription`
- Description: `Fresh roasted coffee delivered monthly`
- Pricing: **Recurring** - Monthly
- Price: `$25.00` (or your price)
- Tax: Taxable
- **Don't create Prices** - your code creates them dynamically

**2. Weekly Subscription** (if you have it)

- Name: `Weekly Coffee Subscription`
- Description: `Fresh roasted coffee delivered weekly`
- Pricing: **Recurring** - Weekly
- Price: `$35.00`
- Tax: Taxable

### One-Off Products (for Shop)

Create individual coffee bags:

**Example Products:**

1. **Ethiopian Yirgacheffe**
   - Description: `Bright, floral notes with citrus undertones. Light roast.`
   - Pricing: **One-time**
   - Price: `$18.00` per bag
   - Tax: Taxable

2. **Colombian Supremo**
   - Description: `Smooth, balanced with chocolate notes. Medium roast.`
   - Pricing: **One-time**
   - Price: `$16.00` per bag
   - Tax: Taxable

3. **Sumatra Mandheling**
   - Description: `Full-bodied, earthy, with herbal complexity. Dark roast.`
   - Pricing: **One-time**
   - Price: `$19.00` per bag
   - Tax: Taxable

### Step 2: Sync to Your Database

After creating in Stripe Dashboard, add to your database:

```bash
# In Rails console (development)
bin/rails console

# Or production
fly ssh console --pty -C "/rails/bin/rails console"
```

```ruby
# Create matching products in your database
Product.create!([
  {
    name: "Ethiopian Yirgacheffe",
    description: "Bright, floral notes with citrus undertones. Light roast.",
    price_cents: 1800,
    product_type: :coffee,
    active: true,
    inventory_count: 50
  },
  {
    name: "Colombian Supremo",
    description: "Smooth, balanced with chocolate notes. Medium roast.",
    price_cents: 1600,
    product_type: :coffee,
    active: true,
    inventory_count: 30
  },
  {
    name: "Sumatra Mandheling",
    description: "Full-bodied, earthy, with herbal complexity. Dark roast.",
    price_cents: 1900,
    product_type: :coffee,
    active: true,
    inventory_count: 25
  }
])

# Create subscription plans (if not already created)
SubscriptionPlan.create!([
  {
    name: "Monthly Subscription",
    description: "Fresh roasted coffee delivered monthly",
    price_cents: 2500,
    frequency: 30,
    active: true
  }
])
```

### Step 3: Test in Sandbox (Test Mode)

1. Switch to **Test mode** in Stripe Dashboard
2. Create same products
3. Visit: http://localhost:3000/shop
4. Test purchase with: `4242 4242 4242 4242`

### Step 4: Enable in Production

1. Switch to **Live mode**
2. Create same products
3. Visit: https://coffee-production.fly.dev/shop
4. Test with real card (small amount)

## Product Guidelines

### Pricing Strategy

- **Subscriptions**: $20-30/month (industry standard)
- **Individual bags**: $15-20 per 12oz bag
- **Premium/specialty**: $22-25 per bag

### Inventory Management

```ruby
# Set inventory count
product.update!(inventory_count: 100)

# Unlimited stock
product.update!(inventory_count: nil)

# Check low stock
Product.where("inventory_count < ?", 10)
```

### Product Images (Later)

Once you have branding:

1. Upload images to Active Storage
2. Add `has_one_attached :image` to Product model
3. Update shop views to display real images

---

**Quick Reference:**

- Test cards: https://stripe.com/docs/testing#cards
- Stripe Dashboard: https://dashboard.stripe.com
- Your shop: https://coffee-production.fly.dev/shop
