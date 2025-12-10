# Acer Coffee - App Structure & Branding Requirements

## Brand Identity Overview

**Name:** Acer Coffee
**Theme:** Small-batch coffee subscription service inspired by Japanese maples and bonsai aesthetics
**Primary Focus:** Dark mode, clean lines, minimalist contrast, natural textures

### Color Palette (Dark Mode Focused)

- **Primary Background:** `#1B1A17` (espresso black)
- **Accent Red (Deshojo Leaf):** `#B93E3E`
- **Creamy White Text:** `#F6F1EB`
- **Coffee Brown:** `#4A2F27`
- **Optional Accent Green:** `#78866B`

### Typography

- **Headers:** "Cormorant Garamond" or "Playfair Display" (Google Fonts serif)
- **Body:** "Inter" or "Work Sans" (Google Fonts sans serif)

### Logo

- White line-art of a Japanese Deshojo maple leaf
- Appears in nav/header on dark background
- Need light and dark versions for flexibility

### Design Principles

- Clean lines and generous whitespace
- Tight border radii (8px or less)
- Minimal shadows, natural textures
- Maintain accessibility and clear contrast for dark mode

---

## Technical Stack

### Framework & Build System

- **Ruby on Rails 8.1.1** (full-stack SSR)
- **Hotwire Stack:**
  - **Turbo** (SPA-like navigation, no page refreshes)
  - **Stimulus** (lightweight JavaScript framework for interactivity)
- **Tailwind CSS** (utility-first styling via `tailwindcss-rails` gem)
- **ImportMap** (native ESM, no bundler needed)
- **PostgreSQL** database
- **Deployed on Fly.io** (production)

### Styling Infrastructure

- **No custom Tailwind config file** - using Tailwind Rails defaults
- **CSS Location:** `app/assets/stylesheets/application.css` (manifest file)
- **Tailwind loaded via:** `stylesheet_link_tag "tailwind"` in layouts
- **Currently using Tailwind utility classes directly in views**
- **No component library** (custom only, not using Tailwind UI/DaisyUI)

### Theme System

- **No dark/light toggle** - fixed dark mode theme preferred
- **Current state:** Light mode (gray-50 backgrounds, white cards)
- **Target:** Convert to dark mode with brand colors

### State Management & Interactivity

- **Hotwire Turbo Frames** (partial page updates)
- **Stimulus Controllers** (for modals, mobile menu, cart interactions)
- **Session-based shopping cart** (no JavaScript state management)

### Stripe Integration

- **Stripe Checkout** (hosted checkout pages, not embedded Elements)
- **Stripe webhooks** for order processing
- **Products:** Both subscriptions and one-time purchases
- **Styling:** Redirect to Stripe Checkout (limited customization, but can pass colors/logo)

---

## Layout Components

### Main Layout (`app/views/layouts/application.html.erb`)

#### Navigation Bar

- **Light mode nav:** White background, gray text
- **Logo:** Text-only "Acer Coffee" (needs maple leaf icon)
- **Links:** Products, About, FAQ, Contact
- **Auth links:** Sign In, Sign Up, Dashboard, Admin (conditionally shown)
- **Mobile menu:** Hamburger button with slide-out menu (Stimulus-powered)

#### Flash Messages

- Positioned at top of main content
- Current colors: blue (notice), red (alert), green (success)

#### Footer

- Social links, copyright
- Dark background with light text

### Admin Layout (`app/views/layouts/admin.html.erb`)

- **Dark nav:** Gray-900 background, white text
- **Admin-specific navigation:** Dashboard, Orders, Customers, Products, Subscription Plans
- **Shield icon** in admin branding
- Similar mobile menu structure

---

## Page Structures

### Home Page (`app/views/pages/home.html.erb`)

```
├── Hero Section
│   ├── H1: "Fresh Roasted Coffee, Delivered"
│   ├── Subtitle paragraph
│   └── CTAs: "Start a Subscription" (blue) | "Shop Single Bags" (white outline)
├── Brand Story (centered text block)
├── How It Works (3-column grid with emojis)
│   ├── 1️⃣ Choose Your Roast & Cadence
│   ├── 2️⃣ Roasted Fresh
│   └── 3️⃣ Delivered on Schedule
└── Featured Coffees (3-card grid)
```

### Shop Page (`app/views/shop/index.html.erb`)

```
├── Page Header
│   ├── Title: "Shop"
│   ├── Subtitle
│   └── Category Tabs: All Products | Coffee | Merchandise
├── Cart Summary Banner (if items in cart, blue background)
└── Product Grid (3 columns, cards)
    ├── Gradient placeholder image (currently amber)
    ├── Product name, description (truncated)
    ├── Price, inventory count
    ├── Quantity selector
    └── "Add to Cart" button (amber-600)
```

### Product Card Structure (Reusable)

- Card container: white bg, rounded-lg, shadow-md
- Image area: 256px height (gradient placeholder currently)
- Content padding: p-6
- Price: Large, bold
- Button: Full width, amber-600 (needs brand color)

### Checkout/Cart Page

- Shopping cart table
- Subtotal, shipping, tax, total breakdown
- "Proceed to Stripe Checkout" button

### Dashboard (Customer Portal)

- Subscription management
- Order history
- Address/payment method management
- Sidebar navigation (collapsible on mobile)

### Admin Panel

- Dark theme (gray-900 nav, gray-50 body)
- Data tables with filters
- Forms for managing products, orders, customers
- Toggle buttons for product visibility, active status

---

## Component Patterns (Current Utility Class Stacks)

### Buttons

**Primary (CTA):**

```html
class="bg-blue-600 text-white px-10 py-4 rounded-lg text-xl font-semibold hover:bg-blue-700
transition-colors"
```

**Secondary (Outline):**

```html
class="bg-white border-2 border-gray-800 text-gray-800 px-10 py-4 rounded-lg text-xl font-semibold
hover:bg-gray-50 transition-colors"
```

**Shop/Cart Button:**

```html
class="w-full bg-amber-600 text-white py-3 rounded-lg hover:bg-amber-700 transition font-medium"
```

### Cards

```html
<div class="bg-white rounded-lg shadow-md overflow-hidden hover:shadow-xl transition">
  <!-- Content -->
</div>
```

### Navigation Links

```html
class="text-gray-700 hover:text-gray-900"
```

### Form Inputs

```html
class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500
focus:border-blue-500"
```

### Badges/Tags

```html
<!-- Active -->
class="px-2 py-1 inline-flex text-xs leading-5 font-semibold rounded-full bg-green-100
text-green-800"

<!-- Product Type -->
class="px-2 py-1 inline-flex text-xs leading-5 font-semibold rounded-full bg-brown-100
text-brown-800"
```

---

## Key Pages & Routes

### Public Routes

- `/` - Home page (hero + featured products)
- `/shop` - Product catalog with category filters
- `/shop/products/:id` - Individual product page
- `/shop/checkout` - Shopping cart
- `/products` - Products listing (duplicate of shop?)
- `/about`, `/faq`, `/contact` - Static pages
- `/subscribe` - Subscription sign-up

### Authenticated Routes

- `/dashboard` - Customer dashboard
- `/dashboard/subscriptions` - Manage subscriptions
- `/dashboard/orders` - Order history
- `/dashboard/addresses` - Shipping addresses
- `/dashboard/payment_methods` - Payment methods

### Admin Routes (Rails namespace)

- `/admin` - Admin dashboard
- `/admin/products` - Product management
- `/admin/orders` - Order management
- `/admin/customers` - Customer management
- `/admin/subscription_plans` - Plan management

---

## Assets & Image Requirements

### Current State

- **No logo files** (text-only "Acer Coffee")
- **Product images:** Gradient placeholders (amber-100 to amber-200)
- **Icons:** Inline SVG (shopping cart, menu, shields)

### Needed Assets

1. **Logo Files:**
   - `logo.svg` (white line-art maple leaf)
   - `logo-dark.svg` (dark variant for light backgrounds)
   - Place in: `app/assets/images/brand/`

2. **Cultivar Icons** (optional for product categories):
   - `palmatum.svg`, `deshojo.svg`, `arakawa.svg`, `kiyohime.svg`
   - Place in: `app/assets/images/brand/cultivar-icons/`

3. **Product Images:**
   - Replace gradient placeholders with actual coffee bag photography
   - Size: ~800x800px recommended for cards
   - Format: WebP or optimized JPEG

### Asset Pipeline

- Assets in `app/assets/images/` are compiled via Sprockets
- Reference in views: `<%= image_tag "brand/logo.svg" %>`
- For CSS: `background-image: image-url('brand/logo.svg')`

---

## Styling Customization Plan

### Step 1: Create Tailwind Config

**File:** `config/tailwind.config.js`

```javascript
module.exports = {
  content: ["./app/views/**/*.html.erb", "./app/helpers/**/*.rb", "./app/javascript/**/*.js"],
  theme: {
    extend: {
      colors: {
        espresso: "#1B1A17",
        deshojo: "#B93E3E",
        cream: "#F6F1EB",
        "coffee-brown": "#4A2F27",
        moss: "#78866B",
      },
      fontFamily: {
        serif: ["Cormorant Garamond", "serif"],
        sans: ["Inter", "sans-serif"],
      },
      borderRadius: {
        brand: "8px",
      },
    },
  },
  plugins: [],
};
```

### Step 2: Add Google Fonts

**In:** `app/views/layouts/application.html.erb` `<head>`

```html
<link rel="preconnect" href="https://fonts.googleapis.com" />
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
<link
  href="https://fonts.googleapis.com/css2?family=Cormorant+Garamond:wght@400;600;700&family=Inter:wght@300;400;500;600;700&display=swap"
  rel="stylesheet"
/>
```

### Step 3: Global Dark Mode Base

**In:** `app/assets/stylesheets/application.css`

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
    @apply font-serif;
  }
}
```

### Step 4: Component Classes

Define reusable classes in `@layer components`:

- `.btn-primary` (deshojo red with hover states)
- `.btn-secondary` (cream outline with hover states)
- `.card` (dark card with subtle borders)
- `.nav-link` (cream text with deshojo hover)

---

## Deployment & Performance Notes

### Fly.io Deployment

- **Asset compilation:** Runs during Docker build
- **Tailwind:** Compiled via `assets:precompile` task
- **Fonts:** Served from Google Fonts CDN (external)
- **Images:** Served from Rails asset pipeline (or could move to CDN)

### Performance Considerations

- **Turbo Drive:** Caches pages, instant navigation
- **Minimal JavaScript:** Stimulus controllers are small, lazy-loaded
- **Font loading:** Use `font-display: swap` in Google Fonts URL
- **Image optimization:** Use WebP, lazy loading (`loading="lazy"`)

---

## Questions for Branding Bot

### Layout & Components

- [x] Layout components: Nav, Hero, Cards, Modals, Forms, Tables
- [x] Component library: Custom only, no UI library
- [x] Dark/light theme: Fixed dark mode (no toggle)
- [x] State management: Hotwire/Stimulus (minimal JS)

### Stripe & Checkout

- [x] Stripe integration: Hosted Checkout (redirect-based)
- [x] Customization: Can pass logo and accent color to Stripe

### Deployment

- [x] Deployment: Fly.io with SSR, Turbo, Importmap
- [x] Asset delivery: Rails asset pipeline (Sprockets)

### Branding Specific

- [ ] **Should we create dark mode variants of all current light-mode components?**
- [ ] **Do you want a single accent color (deshojo red) or use coffee-brown for secondary CTAs?**
- [ ] **Should admin panel stay dark (gray-900) or adopt espresso (#1B1A17) background?**
- [ ] **Do cultivar icons serve a functional purpose (product categories) or just decorative?**
- [ ] **Should we theme Devise auth pages (sign in/sign up) or keep them simple/minimal?**

---

## Next Steps for Implementation

1. **Create `config/tailwind.config.js`** with brand colors
2. **Add Google Fonts** to application layout
3. **Update `application.css`** with base styles and component classes
4. **Convert main layout** (nav, footer) to dark theme
5. **Update button classes** across all views to use brand colors
6. **Replace amber shop colors** with deshojo red
7. **Add logo SVG** to nav and admin panel
8. **Theme Stripe Checkout** with logo + accent color
9. **Update product card placeholders** with brand styling
10. **Test accessibility** (contrast ratios for cream on espresso)

---

## File Structure Reference

```
app/
├── assets/
│   ├── images/
│   │   └── brand/              # ← Logo and cultivar icons go here
│   │       ├── logo.svg
│   │       ├── logo-dark.svg
│   │       └── cultivar-icons/
│   └── stylesheets/
│       └── application.css     # ← Global styles, Tailwind layers
├── javascript/
│   └── controllers/            # Stimulus controllers (mobile menu, modals)
├── views/
│   ├── layouts/
│   │   ├── application.html.erb  # Main public layout
│   │   └── admin.html.erb        # Admin layout
│   ├── pages/
│   │   └── home.html.erb         # Homepage (hero, featured)
│   ├── shop/
│   │   ├── index.html.erb        # Product catalog
│   │   ├── show.html.erb         # Product detail
│   │   ├── checkout.html.erb     # Cart
│   │   └── success.html.erb      # Order confirmation
│   └── dashboard/                # Customer portal views
config/
├── tailwind.config.js        # ← CREATE THIS (brand colors, fonts)
└── importmap.rb              # JavaScript imports (Stimulus, Turbo)
```

---

**Ready for branding!** This snapshot should give your branding bot everything needed to apply the Acer Coffee identity across the app. Let me know if you need any clarifications or additional details!
