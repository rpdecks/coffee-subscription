# Stripe Production Setup Guide

## Current Status

- ✅ Stripe account created
- ✅ Pricing model chosen (subscription-based)
- ✅ Code integration complete (checkout, webhooks, subscriptions)
- ⚠️ Production credentials still using test keys

## Step 1: Activate Your Stripe Account

### Business Information

You'll need to provide:

- [ ] Legal business name: `Acer Coffee` (or your LLC name)
- [ ] Business address: Your Anytime Mailbox address
- [ ] Business type: Sole proprietor / LLC / Corporation
- [ ] Tax ID (EIN or SSN)
- [ ] Industry: Food & Beverage → Coffee/Tea
- [ ] Website: Your production URL
- [ ] Product description: "Subscription-based craft coffee delivery service"

### Identity Verification

Stripe requires identity verification before going live:

- [ ] Upload government-issued ID (driver's license, passport)
- [ ] Confirm your identity details match business registration
- [ ] Wait for Stripe approval (usually < 24 hours)

## Step 2: Create Products in Stripe Dashboard

Navigate to: **Products** → **Add Product**

### For Each Subscription Plan:

Create products matching your `SubscriptionPlan` records:

```ruby
# Run this to see your current plans:
# bin/rails console
# SubscriptionPlan.pluck(:name, :description, :price_cents, :frequency)
```

#### Example: Monthly Subscription

- **Name**: "Monthly Coffee Subscription"
- **Description**: "Fresh roasted coffee delivered monthly"
- **Pricing**:
  - Recurring: Monthly
  - Price: $25.00 (or your price)
- **Tax behavior**: Taxable product/service

Repeat for each plan (e.g., Weekly, Bi-weekly if you have them).

**Note**: You don't need to create Stripe Prices for these products. Your code uses dynamic price creation in `StripeService.create_checkout_session` with `price_data`, which is more flexible for customization.

## Step 3: Get Production API Keys

### In Stripe Dashboard:

1. Toggle from **Test mode** → **Live mode** (top right)
2. Go to **Developers** → **API keys**
3. Copy your **Publishable key** (starts with `pk_live_`)
4. Reveal and copy your **Secret key** (starts with `sk_live_`)

### Update Rails Credentials:

```bash
EDITOR="code --wait" bin/rails credentials:edit --environment production
```

Replace the test keys with live keys:

```yaml
stripe:
  publishable_key: pk_live_YOUR_ACTUAL_KEY_HERE
  secret_key: sk_live_YOUR_ACTUAL_KEY_HERE
  webhooks_secret: # We'll add this in Step 4
```

## Step 4: Configure Webhooks

### Create Webhook Endpoint:

1. In Stripe Dashboard: **Developers** → **Webhooks**
2. Click **Add endpoint**
3. **Endpoint URL**: `https://yourdomain.com/webhooks/stripe`
4. **Description**: "Acer Coffee Production Webhooks"
5. **Events to send**: Select these specific events:
   - ✅ `checkout.session.completed`
   - ✅ `customer.subscription.created`
   - ✅ `customer.subscription.updated`
   - ✅ `customer.subscription.deleted`
   - ✅ `invoice.payment_succeeded`
   - ✅ `invoice.payment_failed`
   - ✅ `payment_method.attached`

### Get Webhook Signing Secret:

1. After creating the endpoint, click on it
2. Click **Reveal** next to "Signing secret"
3. Copy the secret (starts with `whsec_`)

### Update Production Credentials:

```bash
EDITOR="code --wait" bin/rails credentials:edit --environment production
```

Add the webhook secret:

```yaml
stripe:
  publishable_key: pk_live_...
  secret_key: sk_live_...
  webhooks_secret: whsec_YOUR_ACTUAL_SECRET_HERE
```

## Step 5: Configure Payment Settings

### In Stripe Dashboard: **Settings** → **Payments**

- [ ] **Payment methods**: Enable Card (already done likely)
- [ ] **Apple Pay/Google Pay**: Enable (recommended for mobile)
- [ ] **Payment method domain**: Add your domain `yourdomain.com`

### Customer Portal (for self-service)

**Settings** → **Billing** → **Customer portal**

- [ ] Enable customer portal
- [ ] Allow customers to:
  - ✅ Update payment methods
  - ✅ Cancel subscriptions
  - ✅ View invoices
- [ ] Subscription cancellation: "Cancel at end of billing period"
- [ ] Custom domain: Your domain (optional)

**Note**: Your app already has a custom subscription management dashboard, but Stripe's portal is a good backup.

## Step 6: Configure Invoice Settings

### In Stripe Dashboard: **Settings** → **Billing**

#### Invoice Details:

- [ ] **Business name**: Acer Coffee
- [ ] **Support email**: orders@acercoffee.com
- [ ] **Business address**: Your Anytime Mailbox address
- [ ] **Footer**: "Thank you for your business!"

#### Invoice Emails:

- [ ] Enable "Send invoice emails" (Stripe will email receipts)
- [ ] Customize email template with your branding (optional)

#### Tax Settings:

- [ ] **Collect tax automatically**: Enable Stripe Tax (recommended)
  - Automatically calculates sales tax based on customer location
  - Handles nexus requirements
  - Files tax returns (premium feature)
- [ ] OR: Set fixed tax rates by location (if you prefer manual)

## Step 7: Banking Information

### In Stripe Dashboard: **Settings** → **Payouts**

- [ ] **Bank account**: Add your business bank account
  - Account holder name
  - Routing number
  - Account number
- [ ] **Payout schedule**:
  - Daily (default) - funds arrive 2 days after charge
  - Weekly - every Monday
  - Monthly - 1st of month
- [ ] **Statement descriptor**: What appears on customer bank statements
  - Use: `ACERCOFFEE*` or `ACER*COFFEE` (keep it short, recognizable)

### Verify Bank Account:

Stripe will make 2 small deposits to verify. Check your bank in 1-2 days and confirm amounts.

## Step 8: Radar Fraud Prevention

**Settings** → **Radar** (included free)

- [ ] Review default rules (they're good)
- [ ] Set risk threshold: Block payments with risk score > 75
- [ ] Enable 3D Secure: For suspicious transactions
- [ ] Block specific countries: If you only ship domestically

## Step 9: Email Notifications

**Settings** → **Emails**

Configure which emails Stripe sends vs. your app sends:

### Disable Duplicate Emails:

Your Rails app already sends these, so disable in Stripe:

- ❌ Successful payments (you send `order_confirmation`)
- ❌ Failed payments (you send `payment_failed`)
- ❌ Subscription cancelled (you send `subscription_cancelled`)

### Keep Enabled:

- ✅ Payment receipts (required by law in some states)
- ✅ Refund notifications

## Step 10: Test Production Integration

### Before Going Live:

```bash
# 1. Deploy to staging/production with new credentials
git push heroku main  # or your deploy command

# 2. Test checkout flow with real card
# Use your own card for $1 test subscription

# 3. Verify webhook receipt
# Check Stripe Dashboard → Developers → Webhooks → [your endpoint]
# Should show "Succeeded" for webhook deliveries

# 4. Test subscription management
# - Cancel subscription
# - Update payment method
# - Verify webhook events trigger correctly
```

## Step 11: Go Live Checklist

Before accepting real customer payments:

- [ ] Production Stripe keys configured
- [ ] Webhooks endpoint verified and receiving events
- [ ] Bank account added and verified
- [ ] Business identity verified by Stripe
- [ ] Tax collection configured
- [ ] Test checkout completed successfully
- [ ] Subscription cancellation tested
- [ ] Payment failure handling tested
- [ ] Invoice emails configured
- [ ] Statement descriptor set
- [ ] Customer support email configured
- [ ] Terms of Service URL added to checkout
- [ ] Privacy Policy URL added to checkout

## Production Environment Variables

Make sure your production environment has:

```bash
# On Heroku/similar:
heroku config:set RAILS_ENV=production
heroku config:set RAILS_MASTER_KEY=<your_production_master_key>

# Verify Stripe keys are loaded:
heroku run rails console --app your-app-name
> Rails.application.credentials.dig(:stripe, :secret_key)
# Should show: "sk_live_..."
```

## Monitoring Production Payments

### Stripe Dashboard:

- **Home**: Real-time payment dashboard
- **Payments**: All transactions
- **Subscriptions**: Active/cancelled subscriptions
- **Customers**: Customer list with payment history

### Your Rails App:

```bash
# Monitor webhooks
heroku logs --tail | grep "Stripe webhook"

# Check for failed payments
heroku run rails console
> Subscription.where(status: :past_due).count
```

## Common Issues & Solutions

### Issue: Webhooks not being received

**Solution**:

- Verify endpoint URL is publicly accessible
- Check Stripe Dashboard → Webhooks → [endpoint] for errors
- Verify `STRIPE_WEBHOOK_SECRET` is set correctly
- Check Rails logs for webhook signature verification failures

### Issue: Payments succeed but subscription not created

**Solution**:

- Check webhook `checkout.session.completed` is being processed
- Look for errors in Rails logs
- Verify session metadata includes `user_id` and `subscription_plan_id`

### Issue: Bank transfers not arriving

**Solution**:

- Verify bank account in Stripe Dashboard
- Check payout schedule settings
- First payout may be delayed 7-14 days (Stripe's risk assessment)

## Support Resources

- **Stripe Dashboard**: https://dashboard.stripe.com
- **Stripe Docs**: https://stripe.com/docs
- **Stripe Support**: support@stripe.com
- **Your Webhook Endpoint**: https://yourdomain.com/webhooks/stripe
- **Test Cards**: https://stripe.com/docs/testing#cards

## Next Steps After Production Setup

1. **Run seeds in production**: Create products and subscription plans
2. **Test with inner circle**: Have friends test full signup → subscription → cancellation flow
3. **Monitor first week closely**: Watch for webhook issues, failed payments, etc.
4. **Set up Stripe alerts**: Get notified of disputes, failed payouts, etc.
5. **Review analytics weekly**: Track MRR, churn, failed payments

---

**Last Updated**: December 6, 2025
**Status**: Ready to begin production setup
