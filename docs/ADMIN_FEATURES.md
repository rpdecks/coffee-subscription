# Admin Panel Features

## Overview

The Coffee Co. admin panel provides a comprehensive interface for managing subscriptions, orders, customers, products, and subscription plans. Built with Rails 8.1.1 and styled with Tailwind CSS.

## Access

Admin users can access the panel at `/admin` after logging in with an admin account.

**Admin Accounts:**

- `admin@acercoffee.com` / `seedpass`
- `rpdecks@gmail.com` / `seedpass`
- `krilew@gmail.com` / `seedpass`

## Features

### Dashboard (`/admin`)

- **Key Metrics Display:**
  - Active subscriptions count
  - Total customers count
  - Recent orders (last 7 days)
  - Revenue metrics

- **Quick Actions:**
  - Links to all major admin sections
  - Recent activity overview

### Orders Management (`/admin/orders`)

**List View:**

- Paginated list (25 items per page)
- Search by order number, customer email, or name
- Filter by status (pending, processing, roasting, shipped, delivered)
- Filter by date range
- CSV export with all current filters applied
- Shows: order number, customer, status, date, total amount

**Detail View:**

- Complete order information
- Customer details
- Shipping address
- Order items with products and quantities
- Status update controls with email notifications

**Status Updates:**

- Quick actions to change order status
- Automatic email notifications sent to customers:
  - Order confirmation (pending → processing)
  - Roasting notification
  - Shipping notification
  - Delivery confirmation

**CSV Export:**

- Exports all orders matching current filters
- Includes: order number, date, customer, email, phone, status, total, shipping address
- Download filename: `orders_YYYYMMDD_HHMMSS.csv`

### Subscriptions Management (`/admin/subscriptions`)

**List View:**

- Paginated list (25 items per page)
- Search by customer email or name
- Filter by status (active, paused, cancelled)
- Shows: customer, plan, status, quantity, next delivery date

**Detail View:**

- Subscription information
- Associated customer details
- Subscription plan details
- Order history
- Lifecycle controls

**Actions:**

- View full subscription details
- Access customer profile
- View related orders

### Customers Management (`/admin/customers`)

**List View:**

- Paginated list (25 items per page)
- Search by name, email, or phone
- Shows: name, email, phone, join date, subscription status

**Detail View:**

- Customer profile information
- Subscription details (if any)
- Order history
- Addresses
- Payment methods
- Coffee preferences

**CSV Export:**

- Exports all customers matching current filters
- Includes: ID, name, email, phone, join date, subscriptions count, orders count, total spent
- Download filename: `customers_YYYYMMDD_HHMMSS.csv`

### Products Management (`/admin/products`)

**List View:**

- Paginated list (25 items per page)
- Filter by type (coffee, merch)
- Filter by status (active, inactive)
- Search by name or description
- Shows: name, type, price, inventory, status

**Detail View:**

- Product information
- Inventory levels
- Pricing details
- Product status toggle

**Actions:**

- Edit product details
- Update inventory
- Toggle active/inactive status
- Delete product

### Suppliers (`/admin/suppliers`)

Manage green coffee vendors (Sweet Maria's, Royal Coffee New York, Cafe Imports, etc.).

**List View:**

- Paginated list (25 items per page)
- Search by supplier name
- Shows: name, website, contact, green coffee count, total lbs on hand

**Detail View:**

- Supplier info (website, contact, notes)
- Summary stats (total coffees, total lbs)
- Paginated list of their green coffees with links

**Actions:**

- Create / edit / delete suppliers
- "Add Green Coffee" link pre-fills supplier

### Green Coffee (`/admin/green_coffees`)

Track individual lots of unroasted beans purchased from suppliers.

**List View:**

- Paginated list (25 items per page)
- Search by name, lot number, or origin country
- Filter by supplier, freshness status, stock status
- Summary bar: total lbs, total lots, in-stock count, past-crop count
- Freshness badges (fresh / good / aging / past_crop)

**Detail View:**

- Full lot details (origin, variety, process, harvest date, cost)
- Freshness status with badge
- "Used In Products" section showing blend components

**Actions:**

- Create / edit / delete green coffees
- Link to supplier detail page

### Blend Components (nested under Products)

Define blend recipes on any Product's admin show page.

- **Path:** `/admin/products/:id/blend_components/new`
- Select a green coffee, set percentage (0–100%)
- Validates total doesn't exceed 100%
- Prevents duplicate green coffees per product
- Supports single-origin (100%) and multi-origin blends

See [GREEN_COFFEE_SUPPLY_CHAIN.md](GREEN_COFFEE_SUPPLY_CHAIN.md) for full schema and workflow details.

### Subscription Plans Management (`/admin/subscription_plans`)

**List View:**

- Paginated list (25 items per page)
- Filter by status (active, inactive)
- Shows: name, frequency, bags per delivery, price, status

**Detail View:**

- Plan details
- Pricing information
- Active subscriptions count

**Actions:**

- Create new plans
- Edit existing plans
- Toggle active/inactive status
- View subscriptions using this plan

## Technical Details

### Pagination

- 25 items per page across all list views
- Custom Tailwind-styled pagination controls
- Shows total count and current page range
- Previous/Next navigation with disabled states
- Pagination only shown when multiple pages exist

### Search & Filtering

All list views support:

- Real-time search (triggered on form submission)
- Multiple filter options
- Filters persist through pagination
- Clear filters option

### CSV Export

- Respects current search and filter settings
- Generates timestamped filenames
- Includes relevant fields for each resource type
- Uses Ruby's CSV library for reliable generation

### Email Notifications

Automated emails sent for:

- Order status changes
- Subscription updates
- Account notifications

Email configuration:

- **Production:** SendGrid
- **Development:** Mailcatcher (http://localhost:1080)

### Security

- Role-based access control
- Admin-only routes protected by `authenticate_admin!` before_action
- CSRF protection on all forms
- Secure session management

## Daily Automation

### Automated Order Generation

**Schedule:** Daily at 6:00 AM UTC via Heroku Scheduler

**Process:**

1. Finds all active subscriptions due for delivery today
2. Creates orders automatically
3. Generates order items based on subscription plan
4. Sends order confirmation emails to customers
5. Updates next delivery date

**Command:** `bin/generate_subscription_orders`

**Monitoring:**

- Check Heroku Scheduler logs for execution
- Review GenerateSubscriptionOrdersJob logs
- Monitor email delivery through SendGrid dashboard

## Common Tasks

### Adding a New Admin User

```ruby
User.create!(
  email: "newadmin@example.com",
  password: "secure_password",
  password_confirmation: "secure_password",
  first_name: "First",
  last_name: "Last",
  phone: "555-123-4567",
  role: :admin
)
```

### Checking Order Generation

```ruby
# In Rails console
GenerateSubscriptionOrdersJob.perform_now

# Check recent orders
Order.where("created_at > ?", 1.hour.ago).count

# Check subscriptions due today
Subscription.active.where("next_delivery_date <= ?", Date.today)
```

### Resending Order Emails

```ruby
# In Rails console
order = Order.find_by(order_number: "ORD-2025-0123")
OrderMailer.order_confirmation(order).deliver_now
```

### Bulk Status Updates

Use the admin interface to update orders individually, or use Rails console for bulk operations:

```ruby
# Mark old shipped orders as delivered
Order.shipped.where("updated_at < ?", 7.days.ago).find_each do |order|
  order.update!(status: :delivered)
  OrderMailer.order_delivered(order).deliver_now
end
```

## Development

### Seeding Test Data

```bash
bin/rails db:seed:replant
```

Creates:

- 3 admin users
- 30 customers
- 7 products (5 coffee, 2 merch)
- 5 subscription plans
- 25 addresses
- 25 payment methods
- 20 coffee preferences
- 20 subscriptions (various statuses)
- 60+ historical orders

### Running Locally

```bash
bin/dev
```

Starts:

- Rails server on http://localhost:3000
- Tailwind CSS compiler
- Mailcatcher for email testing (if installed)

### Testing Email Locally

1. Install Mailcatcher: `gem install mailcatcher`
2. Run: `mailcatcher`
3. Visit http://localhost:1080 to view emails
4. Emails are configured to send there in development

## Future Enhancements

Potential features to add:

- **Tracking Numbers:** Add tracking number field to shipped orders, display in emails and admin
- **Activity Log:** Track admin actions (who changed what and when)
- **Dashboard Charts:** Revenue trends, subscription growth using Chartkick
- **SMS Notifications:** Twilio integration for shipping updates
- **Inventory Alerts:** Notifications when products run low
- **Customer Analytics:** Lifetime value, churn rate, retention metrics
- **Bulk Actions:** Select multiple orders/customers for bulk operations
- **Advanced Filtering:** Date ranges, amount ranges, multiple status selection
- **Export Scheduling:** Automated daily/weekly CSV reports
