# Coffee Subscription Business - Rails App Roadmap

## Business Overview

- **Target**: 30-50 subscribers initially
- **Volume**: 1,000-2,000 lbs/month
- **Focus**: MVP functionality first, styling/branding later
- **Primary Goal**: Customer-facing subscription management

---

## Technical Stack

### Core Framework

- **Ruby on Rails 7.x** (latest stable)
- **PostgreSQL** - Production-grade database
- **Puma** - Application server
- **Redis** - Session storage, caching, background jobs

### Key Gems & Libraries

- **devise** - User authentication
- **stripe** - Payment processing
- **sidekiq** - Background job processing
- **pundit** or **cancancan** - Authorization/roles
- **kaminari** or **pagy** - Pagination
- **simple_form** - Form builder
- **tailwindcss-rails** - Basic styling (minimal effort)
- **stimulus** - JavaScript framework (Rails default)
- **turbo-rails** - SPA-like experience without complexity

---

## Phase 1: Foundation (Week 1-2)

### 1.1 Project Setup

- [ ] Initialize Rails application with PostgreSQL
- [ ] Set up version control (Git)
- [ ] Configure development environment
- [ ] Set up testing framework (RSpec/Minitest)
- [ ] Configure Tailwind CSS for basic styling

### 1.2 Authentication & User Management

- [ ] Install and configure Devise
- [ ] Create User model with base attributes
- [ ] Add role system (customer, admin)
- [ ] Implement user registration flow
- [ ] Implement login/logout
- [ ] Add password recovery

### 1.3 Database Schema Design

#### Users Table

```ruby
# users
- id (primary key)
- email
- encrypted_password
- role (enum: customer, admin)
- first_name
- last_name
- phone
- created_at, updated_at
```

#### Addresses Table

```ruby
# addresses
- id
- user_id (foreign key)
- address_type (enum: shipping, billing)
- street_address
- street_address_2
- city
- state
- zip_code
- country (default: 'US')
- is_default (boolean)
- created_at, updated_at
```

#### Payment Methods Table

```ruby
# payment_methods
- id
- user_id (foreign key)
- stripe_payment_method_id
- card_brand
- last_four
- exp_month
- exp_year
- is_default (boolean)
- created_at, updated_at
```

---

## Phase 2: Product & Subscription Core (Week 2-3)

### 2.1 Product Catalog

- [ ] Create Product model
- [ ] Build products#index (Products page)
- [ ] Build products#show (Individual product details)
- [ ] Admin interface for product management

#### Products Table

```ruby
# products
- id
- name
- description
- product_type (enum: coffee, merch)
- price_cents (integer, stored in cents)
- weight_oz (for coffee)
- inventory_count
- active (boolean)
- stripe_product_id
- stripe_price_id
- created_at, updated_at
```

### 2.2 Subscription System

- [ ] Create SubscriptionPlan model
- [ ] Create Subscription model
- [ ] Integrate Stripe Subscriptions API
- [ ] Build subscription creation flow
- [ ] Build subscription management interface

#### Subscription Plans Table

```ruby
# subscription_plans
- id
- name (e.g., "Monthly - 2 bags", "Bi-Weekly - 1 bag")
- description
- frequency (enum: weekly, biweekly, monthly)
- bags_per_delivery
- price_cents
- stripe_plan_id
- active (boolean)
- created_at, updated_at
```

#### Subscriptions Table

```ruby
# subscriptions
- id
- user_id (foreign key)
- subscription_plan_id (foreign key)
- status (enum: active, paused, cancelled, past_due)
- stripe_subscription_id
- current_period_start
- current_period_end
- next_delivery_date
- shipping_address_id (foreign key)
- payment_method_id (foreign key)
- created_at, updated_at
```

### 2.3 Coffee Preferences

- [ ] Create CoffeePreference model
- [ ] Link to user and/or subscription
- [ ] Add preference management UI

#### Coffee Preferences Table

```ruby
# coffee_preferences
- id
- user_id (foreign key)
- roast_level (enum: light, medium, dark, variety)
- grind_type (enum: whole_bean, coarse, medium, fine, espresso)
- flavor_notes (array/jsonb)
- special_instructions (text)
- created_at, updated_at
```

---

## Phase 3: Order Management Foundation (Week 3-4)

### 3.1 Order System

- [ ] Create Order model
- [ ] Create OrderItem model
- [ ] Link orders to subscriptions
- [ ] Track order status and fulfillment

#### Orders Table

```ruby
# orders
- id
- user_id (foreign key)
- subscription_id (foreign key, nullable for one-time orders)
- order_number (unique string)
- order_type (enum: subscription, one_time)
- status (enum: pending, processing, roasting, shipped, delivered, cancelled)
- subtotal_cents
- shipping_cents
- tax_cents
- total_cents
- stripe_payment_intent_id
- shipping_address_id (foreign key)
- payment_method_id (foreign key)
- shipped_at
- delivered_at
- created_at, updated_at
```

#### Order Items Table

```ruby
# order_items
- id
- order_id (foreign key)
- product_id (foreign key)
- quantity
- price_cents (price at time of order)
- grind_type
- special_instructions
- created_at, updated_at
```

### 3.2 Payment Processing

- [ ] Set up Stripe webhook handling
- [ ] Handle successful payments
- [ ] Handle failed payments
- [ ] Send payment confirmation emails

---

## Phase 4: Customer Dashboard (Week 4-5)

### 4.1 User Profile Pages

- [ ] Dashboard homepage
- [ ] Profile information management
- [ ] Password change functionality

### 4.2 Address Management

- [ ] List all addresses
- [ ] Add/edit/delete addresses
- [ ] Set default shipping/billing addresses

### 4.3 Payment Methods

- [ ] List saved payment methods
- [ ] Add new payment method (Stripe Elements)
- [ ] Delete payment methods
- [ ] Set default payment method

### 4.4 Subscription Management

- [ ] View active subscription details
- [ ] Modify subscription (change plan, pause, cancel)
- [ ] Update delivery address
- [ ] Update coffee preferences
- [ ] View next delivery date

### 4.5 Order History

- [ ] List past orders
- [ ] View order details
- [ ] Track shipment status
- [ ] Download receipts/invoices

---

## Phase 5: Static & Marketing Pages (Week 5)

### 5.1 Public Pages

- [ ] Home page (landing page)
- [ ] About page
- [ ] Products page (catalog)
- [ ] FAQ page
- [ ] Contact Us page (with form)
- [ ] Privacy Policy & Terms of Service

### 5.2 Contact System

- [ ] Create ContactMessage model
- [ ] Build contact form
- [ ] Send email notifications
- [ ] Admin view of contact messages

---

## Phase 6: Admin Interface (Week 6)

### 6.1 Admin Dashboard

- [ ] Admin-only navigation
- [ ] Overview dashboard (key metrics)
- [ ] Revenue/subscription stats

### 6.2 Order Management

- [ ] View all orders (filterable)
- [ ] Update order status
- [ ] Mark orders as shipped
- [ ] Add tracking information
- [ ] Export order data

### 6.3 Customer Management

- [ ] View customer list
- [ ] View individual customer details
- [ ] View customer order history
- [ ] Manage customer subscriptions

### 6.4 Product Management

- [ ] CRUD operations for products
- [ ] Manage inventory
- [ ] Activate/deactivate products

---

## Phase 7: Polish & Launch Prep (Week 7-8)

### 7.1 Email System

- [ ] Set up ActionMailer with production email service
- [ ] Welcome email on registration
- [ ] Order confirmation emails
- [ ] Shipping notification emails
- [ ] Subscription renewal reminders
- [ ] Payment failure notifications

### 7.2 Background Jobs

- [ ] Set up Sidekiq with Redis
- [ ] Process subscription renewals
- [ ] Generate recurring orders
- [ ] Send scheduled emails
- [ ] Update order statuses

### 7.3 Testing & Quality

- [ ] Add model tests
- [ ] Add controller/integration tests
- [ ] Test payment flows end-to-end
- [ ] Test subscription lifecycle
- [ ] Security audit (basic)

### 7.4 Deployment

- [ ] Set up hosting (Heroku/Render/Railway)
- [ ] Configure production database
- [ ] Set up Redis for production
- [ ] Configure Stripe production keys
- [ ] Set up SSL/HTTPS
- [ ] Configure custom domain
- [ ] Set up monitoring (error tracking)

---

## Future Enhancements (Post-Launch)

### Business Growth Features

- [ ] Referral program
- [ ] Gift subscriptions
- [ ] One-time coffee purchases
- [ ] Merchandise sales
- [ ] Multiple roast/origin options
- [ ] Seasonal/limited offerings

### Technical Improvements

- [ ] Enhanced admin analytics
- [ ] Inventory management system
- [ ] Shipping label generation
- [ ] Customer reviews/ratings
- [ ] Mobile app (optional)
- [ ] Advanced branding/UI redesign

### Operations

- [ ] Integration with roasting equipment/software
- [ ] Automated fulfillment workflows
- [ ] Bulk export for fulfillment
- [ ] SMS notifications
- [ ] Loyalty/rewards program

---

## Key Technical Decisions

### Why These Choices?

**PostgreSQL**: Robust, handles complex queries, great for financial data
**Stripe**: Industry standard, handles subscriptions natively, PCI compliant
**Devise**: Battle-tested authentication, saves weeks of development
**Sidekiq**: Reliable background jobs for recurring billing
**Tailwind CSS**: Minimal config, utility-first, easy to iterate

### MVP Scope

Focus on core loop:

1. User signs up
2. User selects subscription plan
3. User enters payment/shipping info
4. System processes recurring orders
5. Admin fulfills orders
6. User manages subscription

Everything else is secondary.

---

## Development Order (Recommended)

**Start Here:**

1. Rails new + database
2. Authentication (Devise)
3. User roles
4. Basic models (User, Address, Product, SubscriptionPlan)
5. Stripe setup (test mode)
6. Subscription creation flow
7. User dashboard
8. Admin order view
9. Static pages
10. Email notifications
11. Background jobs
12. Testing
13. Deploy to staging
14. Production launch

---

## Estimated Timeline

**MVP Launch**: 6-8 weeks (full-time) or 12-16 weeks (part-time)
**With polish**: +2-4 weeks

This assumes one developer with Rails experience.

---

## Next Steps

1. **Immediate**: Initialize Rails app
2. **Day 1**: Set up authentication
3. **Week 1**: Build core models
4. **Week 2**: Integrate Stripe
5. **Week 3**: Build subscription flow
6. **Week 4**: Build user dashboard
7. **Week 5**: Add static pages
8. **Week 6**: Admin interface
9. **Week 7-8**: Polish and deploy

Ready to start building? Let's initialize the Rails application!
