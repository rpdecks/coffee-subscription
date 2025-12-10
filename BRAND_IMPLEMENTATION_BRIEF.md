# Acer Coffee - Complete Brand Implementation Brief

## Quick Context

You're helping implement a complete dark-mode brand identity for **Acer Coffee**, a small-batch coffee subscription service built with Ruby on Rails 8.1.1 + Tailwind CSS. The brand is inspired by Japanese maples and bonsai aesthetics.

---

## Brand Identity

### Colors (Dark Mode)

```
Primary Background: #1B1A17 (espresso black)
Accent Red:         #B93E3E (deshojo leaf - primary CTAs)
Creamy Text:        #F6F1EB (main text)
Coffee Brown:       #4A2F27 (secondary CTAs)
Accent Green:       #78866B (optional accent)
Admin Tables:       #252320 (slightly lighter for readability)
```

### Typography

- **Headers:** Cormorant Garamond (serif) - 48-64px (H1), 36-48px (H2), 24-32px (H3)
- **Body:** Inter (sans-serif) - 16px regular, 14px small/meta
- **Font Weights:** 400 (body), 600 (headers)
- **Body Text Opacity:** 85% for paragraphs, 70% for meta text

### Logo

- White line-art Japanese Deshojo maple leaf
- Appears in nav/header on dark backgrounds
- Need: `logo.svg` (white) and `logo-dark.svg` (dark variant)

### Design System

- **Border Radius:** 8px (cards), 6px (buttons/inputs), 4px (badges), 12px (modals)
- **Shadows:** Minimal - only on elevated elements (modals, dropdowns)
- **Whitespace:** Generous, clean lines
- **Contrast:** WCAG AA minimum (cream on espresso = 12.56:1 ✅)

---

## Technical Stack

**Framework:**

- Ruby on Rails 8.1.1 (full-stack SSR)
- Hotwire (Turbo + Stimulus for interactivity)
- Tailwind CSS via `tailwindcss-rails` gem
- ImportMap (no bundler)
- PostgreSQL + Deployed on Fly.io

**Current State:**

- Light mode design (gray-50 bg, white cards)
- No Tailwind config file yet
- Using inline utility classes
- No component library (custom only)
- Fixed dark mode preferred (no theme toggle)

**Styling Files:**

- `config/tailwind.config.js` - **DOES NOT EXIST** (needs creation)
- `app/assets/stylesheets/application.css` - manifest file
- Tailwind loaded via: `stylesheet_link_tag "tailwind"` in layouts

---

## Decisions Made

### 1. Full Dark Mode: YES

- Convert all components to espresso background with cream text
- Exception: Admin tables use slightly lighter bg (#252320) for readability

### 2. Color Hierarchy

- **Primary CTA (Deshojo Red #B93E3E):** Subscribe, Add to Cart, Checkout, Confirm Order
- **Secondary CTA (Coffee Brown #4A2F27):** Shop Single Bags, View Product, Edit Profile
- **Tertiary (Cream Outline):** Cancel, Go Back, Skip

### 3. Admin Theme: Espresso-Dark

- Switch from gray-900 to branded espresso (#1B1A17)
- Maintains consistency across public/admin interfaces

### 4. Cultivar Icons: Functional

- 4 maple leaf icons represent roast levels/coffee types:
  - **Palmatum:** Signature blends
  - **Deshojo:** Light roasts
  - **Arakawa:** Medium roasts
  - **Kiyohime:** Dark roasts
- Used in: product badges, filters, category navigation
- Size: 16-20px (cards), 32px (filters)

### 5. Devise Auth Pages: Themed

- Match brand with dark mode
- Centered card on espresso background
- Subtle large maple leaf watermark (faded)

---

## Current Layout Components

### Navigation Bar (`app/views/layouts/application.html.erb`)

```erb
<!-- Current: Light mode, needs conversion -->
<nav class="bg-white shadow-sm">
  <div class="container mx-auto px-4">
    <div class="flex justify-between items-center h-16">
      <a href="/" class="text-xl font-bold text-gray-900">Acer Coffee</a>
      <!-- Links: Products, About, FAQ, Contact -->
      <!-- Auth: Sign In, Sign Up, Dashboard, Admin -->
    </div>
  </div>
</nav>
```

**Needs:**

- Background: espresso (#1B1A17)
- Text: cream (#F6F1EB)
- Logo: Add maple leaf SVG
- Font: Cormorant Garamond for brand name

### Home Page Hero (`app/views/pages/home.html.erb`)

```erb
<h1 class="text-6xl font-bold text-gray-900 mb-6">
  Fresh Roasted Coffee, Delivered
</h1>
<p class="text-2xl text-gray-600 mb-10">
  Small-batch coffee roasted to order
</p>
<div class="flex justify-center space-x-6">
  <a href="/subscribe" class="bg-blue-600 text-white px-10 py-4 rounded-lg">
    Start a Subscription
  </a>
  <a href="/products" class="bg-white border-2 border-gray-800 text-gray-800 px-10 py-4 rounded-lg">
    Shop Single Bags
  </a>
</div>
```

**Needs:**

- H1: Cormorant Garamond, cream text
- Body: Inter, cream 85% opacity
- Primary CTA: deshojo red bg
- Secondary CTA: coffee brown bg (not outline)

### Shop Product Cards (`app/views/shop/index.html.erb`)

```erb
<div class="bg-white rounded-lg shadow-md overflow-hidden hover:shadow-xl transition">
  <!-- Gradient placeholder image (amber) -->
  <div class="h-64 bg-gradient-to-br from-amber-100 to-amber-200"></div>

  <div class="p-6">
    <h3 class="text-xl font-bold text-gray-900 mb-2">Product Name</h3>
    <p class="text-gray-600 text-sm mb-4">Description...</p>
    <span class="text-2xl font-bold text-gray-900">$18.00</span>

    <button class="w-full bg-amber-600 text-white py-3 rounded-lg hover:bg-amber-700">
      Add to Cart
    </button>
  </div>
</div>
```

**Needs:**

- Card bg: espresso with subtle border (cream 10% opacity)
- Text: cream
- Image placeholder: Keep gradient but use espresso tones
- Button: deshojo red
- H3: Cormorant Garamond
- Body: Inter

### Admin Panel (`app/views/layouts/admin.html.erb`)

```erb
<nav class="bg-gray-900 text-white shadow-lg">
  <!-- Admin navigation -->
</nav>
```

**Needs:**

- Background: espresso (#1B1A17) instead of gray-900
- Keep white text (cream)
- Data tables: Use #252320 for table rows

---

## Button Patterns (Current → Target)

### Primary CTA

```html
<!-- CURRENT -->
class="bg-blue-600 text-white px-10 py-4 rounded-lg hover:bg-blue-700"

<!-- TARGET -->
class="bg-deshojo text-cream px-10 py-4 rounded-brand hover:bg-deshojo/90 transition font-semibold"
```

### Secondary CTA

```html
<!-- CURRENT -->
class="bg-white border-2 border-gray-800 text-gray-800 px-10 py-4 rounded-lg"

<!-- TARGET -->
class="bg-coffee-brown text-cream px-10 py-4 rounded-brand hover:bg-coffee-brown/90 transition
font-medium"
```

### Shop Button

```html
<!-- CURRENT -->
class="w-full bg-amber-600 text-white py-3 rounded-lg hover:bg-amber-700"

<!-- TARGET -->
class="w-full bg-deshojo text-cream py-3 rounded-brand hover:bg-deshojo/90 transition font-medium"
```

---

## Files to Deliver

### 1. Config Files (CREATE NEW)

**File:** `config/tailwind.config.js`

```javascript
module.exports = {
  content: ["./app/views/**/*.html.erb", "./app/helpers/**/*.rb", "./app/javascript/**/*.js"],
  theme: {
    extend: {
      colors: {
        espresso: "#1B1A17",
        "espresso-light": "#252320",
        deshojo: "#B93E3E",
        cream: "#F6F1EB",
        "coffee-brown": "#4A2F27",
        moss: "#78866B",
      },
      fontFamily: {
        serif: ["Cormorant Garamond", "Georgia", "serif"],
        sans: ["Inter", "system-ui", "sans-serif"],
      },
      borderRadius: {
        brand: "6px",
      },
    },
  },
  plugins: [],
};
```

### 2. Stylesheet Updates

**File:** `app/assets/stylesheets/application.css`

```css
@tailwind base;
@tailwind components;
@tailwind utilities;

@layer base {
  body {
    @apply bg-espresso text-cream font-sans;
  }

  h1,
  h2,
  h3,
  h4,
  h5,
  h6 {
    @apply font-serif text-cream;
  }

  p {
    @apply text-cream/85;
  }
}

@layer components {
  .btn-primary {
    @apply bg-deshojo text-cream px-6 py-3 rounded-brand font-semibold hover:bg-deshojo/90 transition-colors;
  }

  .btn-secondary {
    @apply bg-coffee-brown text-cream px-6 py-3 rounded-brand font-medium hover:bg-coffee-brown/90 transition-colors;
  }

  .btn-tertiary {
    @apply border-2 border-cream/30 text-cream px-6 py-3 rounded-brand font-medium hover:border-cream/50 transition-colors;
  }

  .card {
    @apply bg-espresso-light border border-cream/10 rounded-lg shadow-sm hover:shadow-md transition-shadow;
  }

  .nav-link {
    @apply text-cream/85 hover:text-cream transition-colors;
  }

  .input-field {
    @apply w-full px-4 py-2 bg-espresso-light border border-cream/20 rounded-brand text-cream placeholder:text-cream/40 focus:ring-2 focus:ring-deshojo focus:border-deshojo transition-colors;
  }
}
```

### 3. Google Fonts Integration

**File:** `app/views/layouts/application.html.erb` (add to `<head>`)

```erb
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Cormorant+Garamond:wght@400;600;700&family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
```

### 4. Logo Placeholder

**File:** `app/assets/images/brand/logo.svg`

```svg
<!-- Simple maple leaf outline - white for dark backgrounds -->
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" fill="none" stroke="#F6F1EB" stroke-width="2">
  <path d="M50 10 L60 35 L85 30 L65 50 L90 65 L60 60 L50 90 L40 60 L10 65 L35 50 L15 30 L40 35 Z"/>
</svg>
```

---

## Key Pages Needing Updates

### Priority 1 (MVP)

1. `app/views/layouts/application.html.erb` - Nav, fonts, logo
2. `app/views/pages/home.html.erb` - Hero, CTAs
3. `app/views/shop/index.html.erb` - Product cards, buttons

### Priority 2 (Complete)

4. `app/views/shop/checkout.html.erb` - Cart styling
5. `app/views/devise/sessions/new.html.erb` - Sign in
6. `app/views/devise/registrations/new.html.erb` - Sign up
7. `app/views/layouts/admin.html.erb` - Admin theme

### Priority 3 (Polish)

8. Cultivar icon integration
9. Stripe branding config
10. Dashboard components

---

## Stripe Branding Config

**For Stripe Checkout customization:**

```ruby
# In StripeService or checkout creation
Stripe::Checkout::Session.create(
  # ... other params
  custom_text: {
    submit: { message: "Complete your Acer Coffee order" }
  },
  # Note: Full branding requires Stripe account settings
  # Configure in dashboard: Settings → Branding
  # - Upload logo.svg
  # - Set accent color: #B93E3E
  # - Set background: #1B1A17
)
```

---

## Accessibility Checklist

- ✅ Cream (#F6F1EB) on espresso (#1B1A17) = 12.56:1 contrast
- ⚠️ Deshojo (#B93E3E) on espresso - verify contrast for buttons
- ✅ Focus rings on all interactive elements (deshojo glow)
- ✅ All icons have aria-labels
- ✅ Proper heading hierarchy
- ✅ Form labels and errors clearly visible

---

## Implementation Notes

- App is live in production - test locally first
- RSpec tests will catch breaking changes
- GitHub Actions runs tests on every commit
- Prefer gradual rollout (page by page)
- Keep Tailwind utility approach (avoid custom CSS unless reusable)

---

## What I Need From You

Please provide complete file contents for:

1. **config/tailwind.config.js** - Full brand config
2. **app/assets/stylesheets/application.css** - Tailwind layers + component classes
3. **Layout updates** - Navigation, fonts, logo integration
4. **Component examples** - Before/After for buttons, cards, forms
5. **Stripe branding snippet** - JSON config for checkout
6. **Cultivar icon usage** - How to integrate in product badges/filters

Deliver as individual files with full paths (not ZIP) so I can review and implement incrementally.

---

**Ready for your deliverables!** Let's transform Acer Coffee into a dark-mode masterpiece. 🍁☕
