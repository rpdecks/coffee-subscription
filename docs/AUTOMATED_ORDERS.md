# Automated Subscription Order Generation

## Overview

The Coffee Co. platform automatically generates orders for active subscriptions based on their delivery schedule. This ensures customers receive their coffee on time without manual intervention.

## How It Works

### Daily Schedule

**Heroku Scheduler Configuration:**

- **Frequency:** Daily
- **Time:** 6:00 AM UTC (10:00 PM PST / 1:00 AM EST)
- **Command:** `bin/generate_subscription_orders`

### Process Flow

1. **Job Execution**

   - `GenerateSubscriptionOrdersJob` runs via Heroku Scheduler
   - Queries for active subscriptions where `next_delivery_date <= today`

2. **Order Creation**

   - For each eligible subscription:
     - Creates a new Order record
     - Generates unique order number (`ORD-YYYY-####`)
     - Sets order type to `:subscription`
     - Calculates totals (subtotal, shipping, tax)
     - Copies shipping address from customer's default address

3. **Order Items**

   - Adds coffee products based on subscription plan
   - Number of items = `bags_per_delivery` from plan
   - Products selected from customer's preferences (if set)
   - Falls back to random coffee products if no preferences

4. **Email Notification**

   - Sends order confirmation email to customer
   - Email includes order details, items, and estimated delivery
   - Uses `OrderMailer.order_confirmation`

5. **Subscription Update**
   - Updates `next_delivery_date` based on plan frequency:
     - Weekly: +7 days
     - Bi-weekly: +14 days
     - Monthly: +30 days

### Service Architecture

**Location:** `app/services/generate_subscription_orders_service.rb`

**Key Methods:**

```ruby
GenerateSubscriptionOrdersService.call
# Returns: { created: [orders], errors: [error_messages] }
```

**Features:**

- Transaction-based to ensure data consistency
- Error handling for individual subscription failures
- Continues processing even if one subscription fails
- Detailed logging for monitoring
- Returns summary of created orders and any errors

### Job Architecture

**Location:** `app/jobs/generate_subscription_orders_job.rb`

**Responsibilities:**

- Executes the service
- Logs execution start and completion
- Records counts of created orders
- Reports errors to logging system

### Email System

**Mailer:** `app/mailers/order_mailer.rb`

**Templates:**

- `app/views/order_mailer/order_confirmation.html.erb`
- `app/views/order_mailer/order_confirmation.text.erb`

**Email Content:**

- Order number and date
- Customer name
- Order items with product names
- Pricing breakdown
- Shipping address
- Estimated delivery date

## Configuration

### Environment Variables

**Development:**

```bash
SMTP_ADDRESS=localhost
SMTP_PORT=1025
# Uses Mailcatcher
```

**Production:**

```bash
SENDGRID_API_KEY=your_api_key
SMTP_ADDRESS=smtp.sendgrid.net
SMTP_PORT=587
SMTP_USERNAME=apikey
SMTP_PASSWORD=$SENDGRID_API_KEY
```

### Heroku Scheduler Setup

1. **Add Heroku Scheduler addon:**

   ```bash
   heroku addons:create scheduler:standard
   ```

2. **Open scheduler dashboard:**

   ```bash
   heroku addons:open scheduler
   ```

3. **Add job:**
   - Command: `bin/generate_subscription_orders`
   - Frequency: Daily
   - Time: 06:00 UTC

### Frequency Calculations

**Subscription Plan Frequencies:**

- `weekly`: 7 days between deliveries
- `biweekly`: 14 days between deliveries
- `monthly`: 30 days between deliveries

**Next Delivery Date Logic:**

```ruby
subscription.next_delivery_date + plan.frequency_in_days.days
```

## Monitoring

### Checking Job Execution

**Heroku Logs:**

```bash
heroku logs --tail --ps scheduler
```

**Look for:**

```
GenerateSubscriptionOrdersJob started
Created X orders for Y subscriptions
GenerateSubscriptionOrdersJob completed
```

### Verifying Orders Created

**Rails Console:**

```ruby
# Check today's automated orders
Order.subscription.where("created_at > ?", Date.today)

# Check specific subscription's next delivery
subscription = Subscription.find(123)
subscription.next_delivery_date

# Check subscriptions due today
Subscription.active.where("next_delivery_date <= ?", Date.today)
```

### Email Delivery Monitoring

**SendGrid Dashboard:**

- Login to SendGrid
- View email activity
- Check delivery rates
- Monitor bounces/spam reports

**Development (Mailcatcher):**

- Visit http://localhost:1080
- View all sent emails
- Test email rendering

## Manual Execution

### Run Job Manually (Console)

```ruby
# Generate orders for all eligible subscriptions
GenerateSubscriptionOrdersJob.perform_now

# Or use the service directly
result = GenerateSubscriptionOrdersService.call
puts "Created: #{result[:created].count}"
puts "Errors: #{result[:errors].count}"
```

### Run Job Manually (Heroku)

```bash
# One-time execution
heroku run bin/rails runner "GenerateSubscriptionOrdersJob.perform_now"

# Or use the script directly
heroku run bin/generate_subscription_orders
```

## Troubleshooting

### No Orders Created

**Check:**

1. Are there active subscriptions?

   ```ruby
   Subscription.active.count
   ```

2. Are any due for delivery?

   ```ruby
   Subscription.active.where("next_delivery_date <= ?", Date.today).count
   ```

3. Do subscriptions have valid data?
   - Customer has default shipping address
   - Subscription plan exists and is valid
   - User account is active

### Emails Not Sending

**Check:**

1. SendGrid API key is set correctly
2. Email configuration in production.rb
3. SendGrid account is active
4. Check SendGrid activity logs
5. Verify email addresses are valid

**Test Email Manually:**

```ruby
order = Order.last
OrderMailer.order_confirmation(order).deliver_now
```

### Duplicate Orders

**Prevention:**

- Service uses transactions for atomicity
- Job should only run once per day
- Check Heroku Scheduler isn't configured multiple times

**Fix:**

```ruby
# Find duplicate orders created today
duplicates = Order.where("created_at > ?", Date.today)
  .group(:subscription_id)
  .having("COUNT(*) > 1")

# Review and manually delete duplicates if needed
```

### Failed Transactions

**Service handles errors gracefully:**

- Continues processing other subscriptions
- Logs errors for review
- Returns error details in result hash

**Review errors:**

```ruby
result = GenerateSubscriptionOrdersService.call
result[:errors].each do |error|
  puts error
end
```

## Testing

### Unit Tests

**Test the service:**

```ruby
# spec/services/generate_subscription_orders_service_spec.rb
RSpec.describe GenerateSubscriptionOrdersService do
  # Test order creation
  # Test email sending
  # Test next_delivery_date updates
  # Test error handling
end
```

### Integration Tests

**Test the job:**

```ruby
# spec/jobs/generate_subscription_orders_job_spec.rb
RSpec.describe GenerateSubscriptionOrdersJob do
  # Test job execution
  # Test service integration
end
```

### Manual Testing (Development)

1. Create test subscription with today's delivery date:

   ```ruby
   subscription = Subscription.first
   subscription.update(next_delivery_date: Date.today)
   ```

2. Run job:

   ```ruby
   GenerateSubscriptionOrdersJob.perform_now
   ```

3. Check results:

   ```ruby
   Order.last # Should be the new order
   subscription.reload.next_delivery_date # Should be updated
   ```

4. Check Mailcatcher for email

## Performance Considerations

### Batch Processing

Currently processes subscriptions individually. For scale:

```ruby
# Process in batches
Subscription.active.due_for_delivery.find_in_batches(batch_size: 100) do |batch|
  batch.each do |subscription|
    # Process subscription
  end
end
```

### Database Queries

- Uses single query to find eligible subscriptions
- Eager loads associations (user, subscription_plan)
- Transactions ensure data consistency
- Minimal database round-trips

### Email Queue

For high volume:

- Consider background job queue (Sidekiq)
- Batch email sending
- Rate limiting for SMTP

## Security

### Access Control

- Job runs with system privileges
- No user authentication required
- Protected by Heroku environment

### Data Validation

- Validates subscription is active
- Verifies user has payment method
- Confirms shipping address exists
- Validates plan configuration

### Error Handling

- Graceful degradation
- Detailed error logging
- No sensitive data in logs
- Transaction rollback on failures

## Maintenance

### Regular Checks

**Weekly:**

- Review Heroku Scheduler logs
- Check order creation counts
- Monitor email delivery rates
- Verify no duplicate orders

**Monthly:**

- Review failed subscriptions
- Update subscription plans if needed
- Clean up old test data
- Check for abandoned subscriptions

### Updating the System

**To change execution time:**

1. Update Heroku Scheduler time
2. No code changes needed

**To change frequency logic:**

1. Update `SubscriptionPlan#frequency_in_days`
2. Update service calculations
3. Test thoroughly before deploying

**To add new features:**

1. Update service class
2. Add tests
3. Update documentation
4. Deploy during low-traffic period
