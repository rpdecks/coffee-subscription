# Webhook Testing Guide

## Local Development Webhook Testing

### Step 1: Start the Stripe CLI listener

```bash
stripe listen --forward-to localhost:3000/webhooks/stripe
```

Note the `whsec_` signing secret it shows and add it to `config/credentials/development.yml.enc`

### Step 2: Start your Rails server

```bash
bin/dev
```

### Step 3: Trigger test webhooks

```bash
# Trigger a checkout completion
stripe trigger checkout.session.completed

# Trigger a subscription creation
stripe trigger customer.subscription.created

# Trigger a successful payment
stripe trigger invoice.payment_succeeded

# Trigger a failed payment
stripe trigger invoice.payment_failed

# Trigger payment method attached
stripe trigger payment_method.attached
```

### Checking Results

**Stripe CLI terminal:** Shows events being forwarded and HTTP responses

```
2025-12-06 20:00:02   --> checkout.session.completed [evt_xxx]
2025-12-06 20:00:02  <--  [200] POST http://localhost:3000/webhooks/stripe
```

**Rails server logs:** Shows webhook processing details

```
Started POST "/webhooks/stripe"
Processing by WebhooksController#stripe
Checkout session completed: cs_test_xxx
```

## Production Webhook Testing

Production webhooks are automatically sent to: `https://acercoffee.com/webhooks/stripe`

No `stripe listen` needed - events go directly from Stripe to your production server.

Check production logs:

```bash
fly logs --app coffee-production
```

## Troubleshooting

**No events showing up?**

- Make sure `stripe listen` is running
- Check that Rails server is running on port 3000
- Verify webhook signing secret in development credentials

**Getting 400 errors?**

- Webhook signature mismatch
- Update development credentials with the `whsec_` secret from `stripe listen`

**Events only work with `stripe trigger` not browser checkout?**

- This is expected! Browser checkouts send to registered webhook endpoints (Stripe Dashboard)
- Local testing uses `stripe trigger` + `stripe listen`
- Production testing uses real checkouts → registered webhook
