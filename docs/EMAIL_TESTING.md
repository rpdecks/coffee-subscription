# Email Testing Guide

## Email Templates to Audit

### OrderMailer (2 templates)

- [ ] `order_confirmation.html.erb` - Sent when order is placed
- [ ] `order_shipped.html.erb` - Sent when order ships

### SubscriptionMailer (5 templates)

- [ ] `subscription_created.html.erb` - Sent when subscription starts
- [ ] `subscription_paused.html.erb` - Sent when subscription paused
- [ ] `subscription_resumed.html.erb` - Sent when subscription resumed
- [ ] `subscription_cancelled.html.erb` - Sent when subscription cancelled
- [ ] `payment_failed.html.erb` (+ text version) - Sent when payment fails

### ContactMailer (1 template)

- [ ] `contact_form.html.erb` (+ text version) - Sent when contact form submitted

### Devise Mailer (5 templates)

- [ ] `confirmation_instructions.html.erb` - Email verification
- [ ] `reset_password_instructions.html.erb` - Password reset
- [ ] `password_change.html.erb` - Password changed notification
- [ ] `email_changed.html.erb` - Email changed notification
- [ ] `unlock_instructions.html.erb` - Account unlock

## Testing Checklist

### Branding Consistency

- [ ] "Acer Coffee" branding appears correctly in all emails
- [ ] Logo displays properly (if using logo)
- [ ] Color scheme matches website
- [ ] Typography is consistent

### Content Review

- [ ] Subject lines are clear and actionable
- [ ] Body copy is concise and friendly
- [ ] CTAs are prominent and clear
- [ ] Business address in footer (if required)
- [ ] Unsubscribe link present (if required)
- [ ] Contact information correct

### Mobile Responsiveness

- [ ] Test on iPhone Safari
- [ ] Test on Android Chrome
- [ ] Test on iPad
- [ ] Single column layout on mobile
- [ ] Buttons are tap-friendly (min 44x44px)
- [ ] Font size readable (min 14px)

### Email Client Compatibility

- [ ] Gmail (web)
- [ ] Gmail (iOS app)
- [ ] Apple Mail (macOS)
- [ ] Apple Mail (iOS)
- [ ] Outlook (web)
- [ ] Yahoo Mail

### Technical Checks

- [ ] Links work correctly
- [ ] Images load (or graceful fallback)
- [ ] Plain text version exists for critical emails
- [ ] Email renders without images
- [ ] No broken HTML/CSS
- [ ] Sender name is "Acer Coffee"
- [ ] From address is orders@acercoffee.com

## How to Test Locally

1. Start Rails server: `bin/rails server`
2. Navigate to page that triggers email
3. Email will open automatically in browser
4. Review email content and styling
5. Test responsive design using browser dev tools

## How to Trigger Each Email

### OrderMailer

```ruby
# In rails console:
order = Order.last
OrderMailer.order_confirmation(order).deliver_now
OrderMailer.order_shipped(order).deliver_now
```

### SubscriptionMailer

```ruby
# In rails console:
subscription = Subscription.last
SubscriptionMailer.subscription_created(subscription).deliver_now
SubscriptionMailer.subscription_paused(subscription).deliver_now
SubscriptionMailer.subscription_resumed(subscription).deliver_now
SubscriptionMailer.subscription_cancelled(subscription).deliver_now
SubscriptionMailer.payment_failed(subscription).deliver_now
```

### ContactMailer

```ruby
# In rails console:
ContactMailer.contact_form(
  name: "Test User",
  email: "test@example.com",
  message: "This is a test message"
).deliver_now
```

### Devise Mailer

```ruby
# In rails console:
user = User.last
user.send_confirmation_instructions
user.send_reset_password_instructions
```

## Inner Circle Testing Plan

### Test Accounts Needed

- 5-10 friends/family members
- Mix of iPhone and Android users
- Mix of email clients (Gmail, Apple Mail, Outlook)

### Test Scenarios

#### Scenario 1: New Customer Journey

1. Sign up for account
2. Verify email address
3. Browse coffee products
4. Create a subscription
5. Receive subscription_created email
6. Receive upcoming order notifications
7. Receive order_confirmation when charged
8. Receive order_shipped when coffee ships

#### Scenario 2: Subscription Management

1. Log in to existing account
2. Pause subscription
3. Receive subscription_paused email
4. Resume subscription
5. Receive subscription_resumed email
6. Cancel subscription
7. Receive subscription_cancelled email

#### Scenario 3: Account Management

1. Reset password
2. Receive reset_password_instructions email
3. Change password
4. Receive password_change email
5. Change email address
6. Receive email_changed email

#### Scenario 4: Customer Support

1. Submit contact form
2. Admin receives contact_form email
3. Verify customer gets response

### Feedback Collection

For each email, testers should check:

- [ ] Email arrived within 1 minute
- [ ] Subject line makes sense
- [ ] Content is clear and helpful
- [ ] Design looks professional
- [ ] Mobile rendering is good
- [ ] Links work correctly
- [ ] Any typos or errors?
- [ ] Overall impression (1-5 stars)

### Devices to Test

- iPhone 13+ (iOS 16+)
- Android phone (recent model)
- iPad
- MacBook
- Windows PC

### Email Clients to Test

- Gmail (web + mobile app)
- Apple Mail (macOS + iOS)
- Outlook (web)
- Yahoo Mail (if any testers use it)

## Notes

- Test with Stripe test cards: 4242 4242 4242 4242
- Use +tag email trick for multiple test accounts: your+test1@gmail.com
- Monitor SendGrid for delivery issues
- Check spam folders if emails don't arrive
