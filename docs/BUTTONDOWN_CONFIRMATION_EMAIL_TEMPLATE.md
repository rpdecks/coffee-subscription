# Buttondown — Confirmation Email Template

This project uses Buttondown for the newsletter signup flow (double opt-in). The confirmation email is configured in Buttondown:

- Buttondown: **Settings → Subscribing → Confirmation email**
- Docs: https://docs.buttondown.com/transactional-emails-confirmation

## Template variables

- `{{ confirmation_url }}` — required confirmation link
- `{{ newsletter.name }}`, `{{ newsletter.description }}`, `{{ newsletter.absolute_url }}`
- `{{ subscriber.email }}`

## Recommended subject

Use something clear and transactional:

- `Confirm your subscription to {{ newsletter.name }}`

## Logo / wordmark in Buttondown

The small logo shown above your confirmation email content is controlled by Buttondown’s **newsletter icon** (the header area in the Modern template / transactional header).

To change it to a wordmark logo:

- In Buttondown, update your newsletter icon (look for settings related to your newsletter profile/icon).
- Use a **PNG** (SVGs are often unreliable in email clients).
- Export at 2x for retina.

### Recommended assets (from your Inkscape master)

Because you want the *full lockup* (tree/cherries/triangle + wordmark), export two PNGs from `acer-logo-full.svg`:

- **Full lockup (for in-body use)**: `acer-logo-full.png`
  - Transparent background (preferred) or white background.
  - Width: ~1200px (or 1000–1600px range), keep aspect ratio.
  - This will be displayed around 240–320px wide in the email body.
- **Full lockup (for Buttondown icon slot)**: `acer-logo-full-icon.png`
  - Same artwork, but export with extra padding around it.
  - Width: ~600–800px.
  - Buttondown will render it small; padding prevents it from feeling cramped.

If the icon still feels too small on the free tier (very likely): add the full lockup at the top of the email body as well (see “Markdown mode template” below). That’s the only reliable way to make it visually prominent without CSS overrides.

Recommended hosting (works now, works later):

- Put the exported PNG at `public/brand/buttondown/acer-logo-full.png` in this app.
- After deploy, it will be available at `https://YOUR_DOMAIN/brand/buttondown/acer-logo-full.png`.

## HTML template (paste into Buttondown)

If you’re using Buttondown’s editor, switch to a mode that preserves HTML (not “plaintext”).

```html
<!-- Acer Coffee — Buttondown confirmation email -->
<table
  role="presentation"
  width="100%"
  cellpadding="0"
  cellspacing="0"
  border="0"
  style="width:100%; background-color:#f3f4f6; margin:0; padding:0;"
>
  <tr>
    <td align="center" style="padding:24px 12px;">
      <table
        role="presentation"
        width="600"
        cellpadding="0"
        cellspacing="0"
        border="0"
        style="width:600px; max-width:600px; background-color:#ffffff; border-radius:12px; overflow:hidden;"
      >
        <tr>
          <td
            align="center"
            style="background-color:#111827; padding:28px 24px; border-bottom:2px solid #1f2937;"
          >
            <a
              href="{{ newsletter.absolute_url }}"
              style="text-decoration:none; color:#ffffff; display:inline-block; font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Arial,sans-serif; font-weight:700; letter-spacing:0.08em;"
            >
              ACER COFFEE
            </a>
          </td>
        </tr>

        <tr>
          <td
            style="padding:32px 24px; font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Arial,sans-serif; font-size:16px; line-height:1.6; color:#1f2937;"
          >
            <h2 style="margin:0 0 12px; font-size:22px; line-height:1.25;">
              Confirm your subscription
            </h2>

            <p style="margin:0 0 16px;">Hi there,</p>

            <p style="margin:0 0 16px;">
              Please confirm your subscription to <strong>{{ newsletter.name }}</strong> by clicking
              the button below.
            </p>

            <div style="text-align:center; margin:24px 0 20px;">
              <a
                href="{{ confirmation_url }}"
                style="display:inline-block; padding:14px 22px; background-color:#8B4513; color:#ffffff; text-decoration:none; border-radius:8px; font-weight:700; font-size:16px;"
              >
                Confirm subscription
              </a>
            </div>

            <p style="margin:0 0 16px; color:#4b5563; font-size:14px;">
              Or copy and paste this link into your browser:<br />
              <a href="{{ confirmation_url }}" style="color:#8B4513; word-break:break-all;"
                >{{ confirmation_url }}</a
              >
            </p>

            <div
              style="background:#f9fafb; padding:16px; border-radius:10px; border:1px solid #e5e7eb; margin:20px 0;"
            >
              <p style="margin:0; color:#6b7280; font-size:14px;">
                If you didn’t request this subscription, you can safely ignore this email.
              </p>
            </div>

            {% if newsletter.description %}
            <hr style="border:0; border-top:1px solid #e5e7eb; margin:24px 0;" />
            <p style="margin:0; color:#6b7280; font-size:14px;">{{ newsletter.description }}</p>
            {% endif %}

            <p style="margin:24px 0 0;">
              Thanks,<br />
              <strong>Acer Coffee</strong>
            </p>
          </td>
        </tr>

        <tr>
          <td
            style="background-color:#f9fafb; padding:20px 24px; text-align:center; font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Arial,sans-serif; font-size:13px; line-height:1.5; color:#6b7280; border-top:1px solid #e5e7eb;"
          >
            <div style="margin-bottom:6px; font-weight:700; color:#1f2937;">
              <a href="{{ newsletter.absolute_url }}" style="color:#1f2937; text-decoration:none;"
                >Acer Coffee</a
              >
            </div>
            <div style="color:#9ca3af;">
              Questions? Reply to this email or reach us at
              <a
                href="mailto:support@acercoffee.com?subject=Newsletter%20help"
                style="color:#9ca3af; text-decoration:none;"
                >support@acercoffee.com</a
              >
            </div>
          </td>
        </tr>
      </table>

      <div
        style="font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Arial,sans-serif; font-size:12px; color:#9ca3af; margin-top:12px;"
      >
        Sent to {{ subscriber.email }}
      </div>
    </td>
  </tr>
</table>
```

## Markdown mode template (works on free tier)

If Buttondown’s “Naked” template isn’t available on your plan, use **Markdown mode** and rely on Buttondown’s built-in template.

If you have a hosted full-lockup PNG URL, replace `YOUR_WORDMARK_URL` below.

Tip: host this on your real domain so it loads in inboxes (e.g. `https://acercoffee.com/brand/buttondown/acer-logo-full.png`).

```markdown
<img src="YOUR_WORDMARK_URL" alt="Acer Coffee" width="280" style="display:block;margin:0 0 16px;max-width:100%;height:auto;" />

Hi there,

Please confirm your subscription to **{{ newsletter.name }}**.

<a href="{{ confirmation_url }}" style="display:inline-block;padding:14px 22px;background:#8B4513;color:#fff;text-decoration:none;border-radius:8px;font-weight:700;">Confirm subscription</a>

If the button doesn’t work, you can use this link instead:
[Confirm subscription]({{ confirmation_url }})

We’ll only email you if you confirm. If you didn’t request this subscription, you can safely ignore this message.

Thanks,<br>
**Acer Coffee**
```

## Plaintext template

```text
Confirm your subscription to {{ newsletter.name }}

Hi there,

Please confirm your subscription by clicking this link:
{{ confirmation_url }}

If you didn’t request this subscription, you can safely ignore this email.

Thanks,
Acer Coffee
```
