# Coffee Subscription Business - Rails Application

A full-stack Ruby on Rails application for managing a coffee subscription business. Built with a focus on user experience, following industry best practices from leading coffee subscription companies.

## 🎯 Project Overview

This MVP supports a small-batch coffee roasting business with:

- **Target Scale**: 1,000-2,000 lbs/month, 30-50 subscribers
- **Core Business**: Coffee subscriptions with future support for one-time purchases and merchandise
- **Design Philosophy**: Minimal, calm aesthetic with guided user flows

## ✨ Features Implemented

### 🔐 Authentication & User Management

- Devise authentication with custom user fields
- Role-based access control (customer, admin)
- Pundit authorization framework
- User registration with first name, last name, phone

### 📦 Product Management

- Coffee and merchandise product catalog
- Inventory tracking
- Active/inactive product status
- Multiple product types support

### 🔄 Subscription System

- **Landing Page**: Explains subscription benefits and value proposition
- **Plan Selection**: Browse available subscription plans
- **Linear Customization Flow**:
  1. Choose your coffee
  2. Select bag size (12oz, 2lb, 5lb)
  3. Pick delivery frequency (weekly, bi-weekly, monthly)
  4. Choose grind type (whole bean, coarse, medium, fine, espresso)
- Subscription plans with flexible frequencies
- Coffee preference management (roast level, grind type)

### 👤 User Dashboard

- Subscription status overview
- Recent orders display
- Quick links to account management
- Address and payment method summaries
- Profile information

### 📄 Static Pages

- Homepage with hero section, features, and "How It Works"
- About page with brand story
- Comprehensive FAQ
- Contact form
- Professional footer

### 🎨 Design & Styling

- Tailwind CSS with custom earth-tone color palette
- Responsive, mobile-friendly layouts
- Minimal, calm aesthetic following design guide principles
- Generous white space and clean typography

## 🛠 Tech Stack

### Core Framework

- **Ruby on Rails 7.2.2** - Latest stable Rails
- **PostgreSQL** - Production-grade database
- **Puma** - Application server
- **Tailwind CSS** - Utility-first styling

### Key Gems

- **devise** - User authentication
- **pundit** - Authorization
- **stripe** - Payment processing (ready to configure)
- **sidekiq** - Background jobs (ready to configure)
- **simple_form** - Form builder
- **pagy** - Pagination
- **rspec-rails** - Testing framework
- **factory_bot_rails** - Test fixtures
- **faker** - Test data generation

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
rspec                        # Run tests (when added)
```

## 📚 Additional Documentation

- **ROADMAP.md** - Full project roadmap
- **SETUP.md** - Setup instructions and status
- **design_guide.md** - Design guidelines

---

**Status**: MVP foundation complete with subscription flow  
**Next**: Stripe integration and admin panel  
**Version**: 0.1.0

Built with ❤️ and ☕
