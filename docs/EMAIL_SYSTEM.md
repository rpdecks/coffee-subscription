# Email Notification System

## Overview

Coffee Co. uses a comprehensive email notification system to keep customers informed about their orders and subscriptions. The system is built with Action Mailer and uses SendGrid for production email delivery.

## Email Types

### Order Emails

**1. Order Confirmation (`order_confirmation`)**

- **Triggered:** When order is created or moves to processing
- **Recipient:** Customer
- **Content:** Order details, items, total, estimated delivery
- **Template:** `app/views/order_mailer/order_confirmation.html.erb`

**2. Order Roasting (`order_roasting`)**

- **Triggered:** When order status changes to `:roasting`
- **Recipient:** Customer
- **Content:** Order is being prepared, roasting details
- **Template:** `app/views/order_mailer/order_roasting.html.erb`

**3. Order Shipped (`order_shipped`)**

- **Triggered:** When order status changes to `:shipped`
- **Recipient:** Customer
- **Content:** Shipment confirmation, estimated delivery date
- **Template:** `app/views/order_mailer/order_shipped.html.erb`
- **Future:** Add tracking number field

**4. Order Delivered (`order_delivered`)**

- **Triggered:** When order status changes to `:delivered`
- **Recipient:** Customer
- **Content:** Delivery confirmation, feedback request
- **Template:** `app/views/order_mailer/order_delivered.html.erb`

### Subscription Emails

**1. Subscription Created (`subscription_created`)**

- **Triggered:** When customer creates new subscription
- **Recipient:** Customer
- **Content:** Subscription details, plan info, next delivery
- **Template:** `app/views/subscription_mailer/subscription_created.html.erb`

**2. Subscription Paused (`subscription_paused`)**

- **Triggered:** When customer pauses subscription
- **Recipient:** Customer
- **Content:** Pause confirmation, resume instructions
- **Template:** `app/views/subscription_mailer/subscription_paused.html.erb`

**3. Subscription Resumed (`subscription_resumed`)**

- **Triggered:** When customer resumes subscription
- **Recipient:** Customer
- **Content:** Resume confirmation, next delivery date
- **Template:** `app/views/subscription_mailer/subscription_resumed.html.erb`

**4. Subscription Cancelled (`subscription_cancelled`)**

- **Triggered:** When customer cancels subscription
- **Recipient:** Customer
- **Content:** Cancellation confirmation, feedback request
- **Template:** `app/views/subscription_mailer/subscription_cancelled.html.erb`

## Mailer Classes

### OrderMailer

**Location:** `app/mailers/order_mailer.rb`

**Methods:**

```ruby
OrderMailer.order_confirmation(order)
OrderMailer.order_roasting(order)
OrderMailer.order_shipped(order)
OrderMailer.order_delivered(order)
```

**Features:**

- Dynamic subject lines with order numbers
- From address: "Coffee Co. <orders@acercoffee.com>"
- Reply-to: support@acercoffee.com
- Branded email templates
- Both HTML and text versions

### SubscriptionMailer

**Location:** `app/mailers/subscription_mailer.rb`

**Methods:**

```ruby
SubscriptionMailer.subscription_created(subscription)
SubscriptionMailer.subscription_paused(subscription)
SubscriptionMailer.subscription_resumed(subscription)
SubscriptionMailer.subscription_cancelled(subscription)
```

**Features:**

- Subscription details included
- Plan information
- Next delivery date (when applicable)
- Branded templates
- Both HTML and text versions

## Email Templates

### Template Structure

**HTML Version:** `app/views/[mailer]/[action].html.erb`

- Full HTML with inline CSS
- Responsive design
- Brand colors and logo
- Clear call-to-action buttons

**Text Version:** `app/views/[mailer]/[action].text.erb`

- Plain text fallback
- All essential information
- ASCII formatting for readability

### Styling

**Inline CSS:**

- Required for email clients
- Tailwind classes converted to inline styles
- Brand colors: Green (#10B981), Gray (#6B7280)

**Responsive Design:**

- Mobile-first approach
- Max-width containers
- Readable font sizes
- Touch-friendly buttons

## Configuration

### Development Environment

**config/environments/development.rb:**

```ruby
config.action_mailer.delivery_method = :smtp
config.action_mailer.smtp_settings = {
  address: 'localhost',
  port: 1025
}
config.action_mailer.default_url_options = {
  host: 'localhost',
  port: 3000
}
```

**Using Mailcatcher:**

```bash
gem install mailcatcher
mailcatcher
# Visit http://localhost:1080
```

### Production Environment

**config/environments/production.rb:**

```ruby
config.action_mailer.delivery_method = :smtp
config.action_mailer.smtp_settings = {
  address: 'smtp.sendgrid.net',
  port: 587,
  domain: 'yourdomain.com',
  user_name: 'apikey',
  password: ENV['SENDGRID_API_KEY'],
  authentication: :plain,
  enable_starttls_auto: true
}
config.action_mailer.default_url_options = {
  host: 'www.yourdomain.com',
  protocol: 'https'
}
```

### SendGrid Setup

1. **Create SendGrid Account:**
   - Sign up at sendgrid.com
   - Verify your email
   - Complete sender authentication

2. **Create API Key:**
   - Settings → API Keys → Create API Key
   - Select "Restricted Access"
   - Enable: Mail Send
   - Copy API key

3. **Set Environment Variable:**

  Fly (recommended):

  ```bash
  flyctl secrets set SENDGRID_API_KEY=your_api_key -a coffee-production
  ```

  After updating secrets, restart so all Machines pick up the new values:

  ```bash
  flyctl apps restart coffee-production
  ```

4. **Verify Domain (Recommended):**
   - Settings → Sender Authentication → Domain Authentication
   - Add DNS records to your domain
   - Verify domain

5. **Configure From Address:**
   - Use verified domain in mailers
   - Example: orders@yourdomain.com

## Operational Notes

### When SMTP credentials break

If SendGrid rejects the credential, Rails may raise `Net::SMTPAuthenticationError` with a message like:

`535 Authentication failed: The provided authorization grant is invalid, expired, or revoked`

This can happen if the API key was rotated, disabled, deleted, or created without the required permissions.

### Monitoring recommendation

At minimum, alert on occurrences of `Net::SMTPAuthenticationError` / `535 Authentication failed` in production logs via a Fly log drain + your log/alerting provider.

## Triggering Emails

### From Controllers

**Order Status Updates:**

```ruby
# app/controllers/admin/orders_controller.rb
def update_status
  if @order.update(status: params[:status])
    case @order.status.to_sym
    when :processing
      OrderMailer.order_confirmation(@order).deliver_later
    when :roasting
      OrderMailer.order_roasting(@order).deliver_later
    when :shipped
      OrderMailer.order_shipped(@order).deliver_later
    when :delivered
      OrderMailer.order_delivered(@order).deliver_later
    end
  end
end
```

**Subscription Updates:**

```ruby
# app/controllers/subscriptions_controller.rb
def pause
  if @subscription.pause!
    SubscriptionMailer.subscription_paused(@subscription).deliver_later
  end
end
```

### From Jobs

**Automated Orders:**

```ruby
# app/services/generate_subscription_orders_service.rb
order = Order.create!(...)
OrderMailer.order_confirmation(order).deliver_later
```

### From Console

**Manual Sending:**

```ruby
# Send immediately
order = Order.find(123)
OrderMailer.order_confirmation(order).deliver_now

# Queue for background delivery
OrderMailer.order_confirmation(order).deliver_later
```

## Testing

### Preview Emails

**Action Mailer Previews:**

Location: `spec/mailers/previews/`

Access: http://localhost:3000/rails/mailers

**Example Preview:**

```ruby
# spec/mailers/previews/order_mailer_preview.rb
class OrderMailerPreview < ActionMailer::Preview
  def order_confirmation
    OrderMailer.order_confirmation(Order.first)
  end

  def order_shipped
    OrderMailer.order_shipped(Order.shipped.first)
  end
end
```

### Development Testing

1. **Start Mailcatcher:**

   ```bash
   mailcatcher
   ```

2. **Trigger email action in app**

3. **View in Mailcatcher:**
   - Visit http://localhost:1080
   - See all sent emails
   - Check HTML and text versions
   - Verify links work

### Production Testing

**Test SendGrid Integration:**

```ruby
# In production console
test_order = Order.first
OrderMailer.order_confirmation(test_order).deliver_now

# Check SendGrid Activity Dashboard
```

**SendGrid Activity:**

- Login to SendGrid
- Email Activity
- Filter by recipient
- View delivery status

## Monitoring

### SendGrid Dashboard

**Metrics to Watch:**

- Delivery rate (should be >95%)
- Bounce rate (should be <5%)
- Spam reports (should be <0.1%)
- Open rate (industry average: 15-25%)
- Click rate (industry average: 2-5%)

### Application Logs

**Search for:**

```
Sent mail to customer@example.com
OrderMailer#order_confirmation
Completed in XXms
```

**Heroku Logs:**

```bash
heroku logs --tail | grep "Mailer"
```

### Error Handling

**Failed Deliveries:**

- Logged in application logs
- Visible in SendGrid activity
- Check bounce reasons
- Update invalid email addresses

## Troubleshooting

### Emails Not Received

**Check:**

1. **Spam folder**
2. **SendGrid activity** - Was it sent?
3. **Bounces** - Invalid email address?
4. **Email configuration** - Correct SMTP settings?
5. **API key** - Valid and not expired?

**Verify SendGrid:**

```ruby
# Test connection
ActionMailer::Base.smtp_settings
# Should show SendGrid configuration
```

### Emails Look Wrong

**Check:**

1. **Template rendering** - Preview locally
2. **Inline CSS** - Email clients ignore external styles
3. **Image paths** - Use full URLs with protocol
4. **Test in multiple clients** - Gmail, Outlook, Apple Mail

### Slow Email Delivery

**Solutions:**

1. Use `deliver_later` instead of `deliver_now`
2. Configure background job processor (Sidekiq)
3. Batch email sending for large volumes
4. Monitor SendGrid rate limits

### Development Emails Going to Production

**Prevent with:**

```ruby
# config/environments/development.rb
config.action_mailer.perform_deliveries = true
config.action_mailer.raise_delivery_errors = true

# Use letter_opener gem to intercept
gem 'letter_opener', group: :development

config.action_mailer.delivery_method = :letter_opener
```

## Best Practices

### Email Content

- **Clear subject lines** with order/subscription numbers
- **Personalization** with customer name
- **Action buttons** for main CTA (Track Order, View Details)
- **Contact information** for support
- **Unsubscribe link** for marketing emails
- **Mobile-first design** - most users read on mobile

### Deliverability

- **Verify domain** with SendGrid
- **Warm up IP** gradually increase volume
- **Clean list** remove bounced emails
- **Avoid spam triggers** excessive caps, exclamation points
- **Include plain text** version always
- **Test spam score** before sending

### Performance

- **Use deliver_later** for non-critical emails
- **Background jobs** for bulk sending
- **Rate limiting** respect SMTP limits
- **Monitoring** track delivery metrics

### Security

- **Validate recipients** before sending
- **Sanitize content** prevent XSS in user data
- **Secure credentials** use environment variables
- **HTTPS links** all URLs should use secure protocol
- **SPF/DKIM** configure for domain

## Future Enhancements

### Planned Features

1. **Email Preferences**
   - Customer dashboard for email settings
   - Opt-in/out for specific email types
   - Frequency preferences

2. **Rich Content**
   - Product images in emails
   - Coffee brewing tips
   - Recipe suggestions

3. **Tracking**
   - Open tracking via SendGrid
   - Click tracking for links
   - A/B testing for subject lines

4. **Advanced Notifications**
   - Subscription renewal reminders
   - Low inventory alerts for favorites
   - Personalized recommendations

5. **Transactional SMS**
   - Critical updates via Twilio
   - Shipping notifications
   - Delivery confirmations

## Resources

- [Action Mailer Guide](https://guides.rubyonrails.org/action_mailer_basics.html)
- [SendGrid Documentation](https://docs.sendgrid.com/)
- [Email Testing Best Practices](https://litmus.com/blog/)
- [Email Design Guide](https://www.campaignmonitor.com/dev-resources/)
