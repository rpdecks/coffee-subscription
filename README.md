# Coffee Co. - Subscription Coffee Service

A full-featured coffee subscription platform built with Rails 8.1.1, enabling customers to manage recurring coffee deliveries and administrators to oversee the entire operation.

## 🎯 Overview

Coffee Co. is a production-ready subscription platform for coffee roasting businesses with:

- **Automated Operations**: Daily order generation, email notifications, subscription management
- **Admin Tools**: Comprehensive dashboard with pagination, search, filtering, and CSV export
- **Customer Experience**: Self-service subscription management, order tracking, email updates
- **Scale Ready**: Built for 30-2,000+ active subscriptions with efficient data handling

## ✨ Features

### Customer Features

- 🔐 User authentication and account management
- ☕ Browse and purchase coffee products
- 📦 Subscription management (create, pause, resume, cancel)
- 🗓️ Flexible delivery schedules (weekly, bi-weekly, monthly)
- 💳 Secure payment processing with Stripe
- 📍 Multiple shipping addresses
- ⚙️ Coffee preferences (roast level, grind type)
- 📧 Email notifications for orders and subscriptions
- 📊 Order history and tracking

### Admin Features

- 📊 Comprehensive dashboard with key metrics
- 👥 Customer management with search and filtering
- 📦 Order management with status updates
- 🔄 Subscription oversight and management
- ☕ Product catalog management (coffee and merch)
- 📋 Subscription plan configuration
- 📈 Pagination for large datasets (25 items per page)
- 📥 CSV export for orders and customers
- ✉️ Automated email notifications
- 🤖 Automated daily order generation

### Automated Features

- **Daily Order Generation**: Automatic order creation for active subscriptions at 6 AM UTC
- **Email Notifications**: Order confirmations, status updates, subscription lifecycle events
- **Smart Scheduling**: Next delivery date calculations based on plan frequency
- **Error Handling**: Graceful error handling with detailed logging

## 🛠 Tech Stack

- **Framework:** Ruby on Rails 8.1.1
- **Ruby Version:** 3.3.10
- **Database:** PostgreSQL
- **CSS Framework:** Tailwind CSS 4.1
- **Payment Processing:** Stripe
- **Email Service:** SendGrid (production), Mailcatcher (development)
- **Authentication:** Devise
- **Pagination:** Pagy
- **Job Scheduling:** Heroku Scheduler
- **Hosting:** Heroku

## 🚀 Getting Started

### Prerequisites

- Ruby 3.1.6+
- PostgreSQL
- Node.js (for asset compilation)

### Installation

1. **Install dependencies**

   ```bash
   bundle install
   ```

2. **Set up the database**

   ```bash
   rails db:create
   rails db:migrate
   rails db:seed
   ```

3. **Start the development server**

   ```bash
   bin/dev
   ```

4. **Visit the application**
   Open http://localhost:3000

### Test Accounts

The seed data creates test accounts you can use:

```
Admin: admin@coffeeco.com / password123
Customer 1: john@example.com / password123
Customer 2: jane@example.com / password123
```

## 📊 Database Schema

### Core Models

- **Users** - Authentication, profile, role
- **Products** - Coffee and merchandise catalog
- **Subscription Plans** - Plan configurations
- **Subscriptions** - User subscriptions
- **Orders & Order Items** - Order tracking
- **Addresses** - Shipping and billing
- **Coffee Preferences** - Roast level and grind type

## 🗺 Key Routes

```
GET  /                      # Homepage
GET  /subscribe             # Subscription landing
GET  /subscribe/plans       # View plans
GET  /subscribe/customize   # Customize subscription
GET  /products              # Product catalog
GET  /dashboard             # User dashboard
```

## 🎯 What's Next

### Immediate Priorities

- Stripe payment integration
- Subscription management (pause, skip, cancel)
- Dashboard features (address, payment methods)
- Admin interface

See **ROADMAP.md** for the complete development plan.

## 📝 Development Commands

```bash
rails db:migrate             # Run migrations
rails db:seed                # Load seed data
rails console                # Rails console
rspec                        # Run tests
```

## 🚀 Deployment

**⚠️ IMPORTANT: Use the safe deploy script, not `fly deploy` directly**

```bash
# Safe production deployment (with confirmations)
bin/deploy-production

# DO NOT use directly:
# fly deploy  ❌ (bypasses safety checks)
```

The deploy script will:

1. Check for uncommitted changes
2. Run full test suite
3. Ask for confirmation before deploying
4. Deploy to production

## 📚 Additional Documentation

- **ROADMAP.md** - Full project roadmap
- **SETUP.md** - Setup instructions and status
- **design_guide.md** - Design guidelines

---

**Status**: MVP foundation complete with subscription flow
**Next**: Stripe integration and admin panel
**Version**: 0.1.0

Built with ❤️ and ☕
