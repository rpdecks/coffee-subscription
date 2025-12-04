# Testing Guide - Stripe Integration

## UI Testing (Manual)

### Prerequisites

1. **Stripe Test Keys Configured** - Already done! ✅
2. **Database seeded** with at least one subscription plan:

   ```bash
   bin/rails db:seed
   ```

3. **Server running**:

   ```bash
   bin/rails server
   ```

### Test Scenarios

#### 1. New Subscription Flow (Happy Path)

**Goal:** Test complete checkout flow from landing to success

1. Visit `http://localhost:3000/subscribe`
2. Click "View Plans" or similar CTA
3. Select a subscription plan
4. Customize your preferences (bag size, coffee type, etc.)
5. Click "Checkout"
6. **If not logged in:** You'll be redirected to sign up/login
7. **At Stripe Checkout:**
   - Use test card: `4242 4242 4242 4242`
   - Expiry: Any future date (e.g., `12/25`)
   - CVC: Any 3 digits (e.g., `123`)
   - ZIP: Any 5 digits (e.g., `12345`)
8. Complete checkout
9. **Expected:** Redirect to success page with subscription details

**What to verify:**

- ✅ User created in Stripe (check Stripe Dashboard → Customers)
- ✅ Subscription created in Stripe (check Stripe Dashboard → Subscriptions)
- ✅ Subscription record created in database
- ✅ User can view subscription in dashboard

#### 2. Payment Method Management

**Goal:** Test adding, setting default, and removing payment methods

1. Log in to your account
2. Go to `/dashboard/payment_methods`
3. **Add a card:**
   - Click "Add Payment Method"
   - Test cards to use:
     - Success: `4242 4242 4242 4242`
     - Declined: `4000 0000 0000 0002`
     - Requires authentication: `4000 0025 0000 3155`
   - Complete the form
4. **Set as default:**
   - Add multiple cards
   - Click "Set as Default" on a non-default card
   - Verify default badge moves
5. **Remove a card:**
   - Try removing the default card with active subscription (should be blocked)
   - Remove a non-default card (should work)

**What to verify:**

- ✅ Cards appear in Stripe Dashboard → Customers → Payment Methods
- ✅ Cannot remove default card if subscription is active
- ✅ Removing card detaches it from Stripe

#### 3. Subscription Management

**Goal:** Test pause, resume, and cancel functionality

1. Go to `/dashboard/subscriptions/:id` (your subscription detail page)
2. **Pause subscription:**
   - Click "Pause Subscription"
   - Verify status changes to "Paused"
   - Check Stripe Dashboard - subscription should be paused
3. **Resume subscription:**
   - Click "Resume Subscription"
   - Verify status changes to "Active"
   - Verify next delivery date is set
4. **Skip delivery:**
   - Click "Skip Next Delivery"
   - Verify next delivery date is pushed forward
5. **Cancel subscription:**
   - Click "Cancel Subscription"
   - Verify cancellation message mentions "end of billing period"
   - Check Stripe - should be set to cancel at period end

**What to verify:**

- ✅ Status syncs between your app and Stripe
- ✅ Cancellation is at period end (not immediate)
- ✅ Paused subscriptions don't generate invoices

#### 4. Webhook Testing (Advanced)

**Goal:** Test webhook event processing

### Option A: Using Stripe CLI (Recommended)

```bash
# Install Stripe CLI
brew install stripe/stripe-cli/stripe

# Login to Stripe
stripe login

# Forward webhooks to local server
stripe listen --forward-to localhost:3000/webhooks/stripe

# Trigger test events
stripe trigger payment_intent.succeeded
stripe trigger customer.subscription.updated
```

### Option B: Using Stripe Dashboard\*\*

1. Go to Stripe Dashboard → Developers → Webhooks
2. Click "Add endpoint"
3. URL: `https://your-domain.com/webhooks/stripe` (requires public URL)
4. Select events to listen for
5. Test by creating actions in Stripe Dashboard

## Automated Testing

### Run All Stripe Tests

```bash
# All Stripe-related tests
bundle exec rspec spec/services/stripe_service_spec.rb
bundle exec rspec spec/requests/webhooks_spec.rb
bundle exec rspec spec/requests/dashboard/payment_methods_spec.rb
bundle exec rspec spec/requests/dashboard/subscriptions_management_spec.rb

# Or run all at once
bundle exec rspec spec/services/stripe_service_spec.rb \
                  spec/requests/webhooks_spec.rb \
                  spec/requests/dashboard/payment_methods_spec.rb \
                  spec/requests/dashboard/subscriptions_management_spec.rb
```

### Run Specific Test Groups

```bash
# Only service layer tests
bundle exec rspec spec/services/stripe_service_spec.rb

# Only webhook tests
bundle exec rspec spec/requests/webhooks_spec.rb

# Only payment method tests
bundle exec rspec spec/requests/dashboard/payment_methods_spec.rb

# Only subscription management tests
bundle exec rspec spec/requests/dashboard/subscriptions_management_spec.rb
```

### Run Specific Test Cases

```bash
# Specific describe block
bundle exec rspec spec/services/stripe_service_spec.rb:10

# Specific test
bundle exec rspec spec/services/stripe_service_spec.rb:25
```

## Test Coverage Summary

**Service Layer:**

- ✅ Customer creation and management
- ✅ Checkout session creation
- ✅ Payment method attachment/detachment
- ✅ Subscription pause/resume/cancel
- ✅ Error handling

**Webhooks:**

- ✅ checkout.session.completed → creates subscription
- ✅ customer.subscription.updated → updates status
- ✅ customer.subscription.deleted → marks cancelled
- ✅ invoice.payment_succeeded → creates order
- ✅ invoice.payment_failed → marks past_due
- ✅ Invalid signature handling

**Payment Methods:**

- ✅ List payment methods
- ✅ Add new payment method
- ✅ Set default payment method
- ✅ Remove payment method
- ✅ Validation (cannot remove default with active subscription)

**Subscription Management:**

- ✅ View subscription details
- ✅ Update subscription
- ✅ Pause subscription (synced with Stripe)
- ✅ Resume subscription (synced with Stripe)
- ✅ Cancel subscription (at period end)
- ✅ Skip delivery

## Stripe Test Cards Reference

### Basic Cards

- **Success:** `4242 4242 4242 4242`
- **Declined:** `4000 0000 0000 0002`
- **Insufficient funds:** `4000 0000 0000 9995`

### Authentication Required (3D Secure)

- **Authentication required:** `4000 0025 0000 3155`
- **Authentication fails:** `4000 0000 0000 3220`

### Specific Scenarios

- **Expired card:** `4000 0000 0000 0069`
- **Processing error:** `4000 0000 0000 0119`
- **Incorrect CVC:** `4000 0000 0000 0127`

All test cards:

- Use any future expiry date
- Use any 3-digit CVC
- Use any 5-digit ZIP code

## Common Issues & Solutions

### Issue: "No Stripe customer found"

**Solution:** User needs to sign up or webhook hasn't processed yet. Check that `CreateStripeCustomerJob` ran successfully.

### Issue: "Checkout session URL is nil"

**Solution:** Verify Stripe keys are configured correctly in credentials. Check logs for API errors.

### Issue: "Payment method not attaching"

**Solution:** Ensure user has a Stripe customer ID. Try running `user.ensure_stripe_customer` in console.

### Issue: "Webhooks not receiving events"

**Solution:**

- In development: Use Stripe CLI to forward events
- In production: Verify webhook endpoint is publicly accessible
- Check webhook secret is configured

### Issue: Tests failing with "Stripe::AuthenticationError"

**Solution:** Mock Stripe API calls in tests (already done in test suite)

## Next Steps After Manual Testing

1. ✅ Verify Stripe Dashboard shows all expected data
2. ✅ Run automated test suite
3. ✅ Test failed payment scenarios
4. ✅ Test webhook signature verification (add webhook_secret to credentials)
5. ✅ Test with Stripe CLI for local webhook testing
6. Deploy to staging and test with real Stripe test mode
7. Set up monitoring for failed webhooks
8. Configure production webhooks in Stripe Dashboard

## Monitoring & Debugging

### Check Logs

```bash
# Rails logs
tail -f log/development.log | grep -i stripe

# Job logs
tail -f log/development.log | grep -i job
```

### Rails Console Debugging

```ruby
# Check user's Stripe customer
user = User.find(1)
user.stripe_customer_id

# Manually create customer
StripeService.create_customer(user)

# Check subscription status
subscription = Subscription.find(1)
subscription.stripe_subscription_id

# Retrieve from Stripe
Stripe::Subscription.retrieve(subscription.stripe_subscription_id)
```

### Stripe Dashboard

- **Customers:** See all test customers and their payment methods
- **Subscriptions:** View subscription status and billing history
- **Payments:** See all successful and failed payments
- **Webhooks:** View webhook delivery history and retry failed webhooks
- **Logs:** See all API requests for debugging
