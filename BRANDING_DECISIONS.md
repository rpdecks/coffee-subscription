# Acer Coffee - Branding Decisions

## Final Scope Choices for Design Bot

### 1. Theme All Components Dark Mode?

**Choice: Yes, update all to bg-espresso, text-cream**

**Rationale:**

- Full dark mode creates immersive, premium coffee experience
- Matches Japanese aesthetic (minimal, contemplative)
- Better for evening browsing (when people shop for morning coffee!)
- Consistent brand experience across all touchpoints

**Exception:** Keep admin data tables with slight contrast (maybe espresso-lighter) for readability

---

### 2. Secondary CTA Color

**Choice: Coffee brown (#4A2F27)**

**Rationale:**

- Deshojo red for primary actions (Subscribe, Add to Cart, Buy Now)
- Coffee brown for secondary/supportive actions (Learn More, View Details, Cancel)
- Creates visual hierarchy
- Coffee brown ties to product while deshojo creates urgency

**Usage Guide:**

- **Primary CTA (deshojo red):** Subscribe, Add to Cart, Checkout, Confirm Order
- **Secondary CTA (coffee brown):** Shop Single Bags, View Product, Edit Profile, Manage Subscription
- **Tertiary (cream outline):** Cancel, Go Back, Skip

---

### 3. Admin Theme

**Choice: Switch to branded espresso-dark mode**

**Rationale:**

- Consistent brand experience for team members
- Admin panel is customer-facing when sharing screenshots/reports
- Less jarring when switching between admin and public site
- Shows attention to detail

**Note:** Keep tables/data grids with slightly lighter bg for scan-ability (maybe `#252320` - just a touch lighter than espresso)

---

### 4. Cultivar Icons Purpose

**Choice: Functional (used in filters/navigation)**

**Rationale:**

- Use cultivar icons to represent coffee types/origins:
  - **Palmatum:** Signature/house blends
  - **Deshojo:** Light roasts / floral notes
  - **Arakawa:** Medium roasts / balanced
  - **Kiyohime:** Dark roasts / bold
- Appears in:
  - Product category badges
  - Shop filter chips
  - Subscription preference selection
  - Product cards (small icon next to roast level)
- Creates unique visual language for coffee expertise

**Implementation:**

- Small (16-20px) icons in product cards
- Larger (32px) in filter navigation
- Include tooltip/label for accessibility

---

### 5. Devise Auth Pages Themed?

**Choice: Yes, match brand**

**Rationale:**

- First impression for new customers (sign up page)
- Professional, cohesive experience
- Dark theme reduces eye strain during sign-in
- Shows we care about every detail

**Keep it minimal:**

- Centered card on espresso background
- Cream text, deshojo CTA buttons
- Simple maple leaf watermark (subtle, large, faded in background)

---

## Additional Guidance for Design Bot

### Typography Hierarchy

```
H1: Cormorant Garamond, 48px-64px, font-weight: 600, cream
H2: Cormorant Garamond, 36px-48px, font-weight: 600, cream
H3: Cormorant Garamond, 24px-32px, font-weight: 600, cream
Body: Inter, 16px, font-weight: 400, cream (with 85% opacity for body text)
Small/Meta: Inter, 14px, font-weight: 400, cream (with 70% opacity)
```

### Border Radius Standards

- Cards: 8px
- Buttons: 6px
- Inputs: 6px
- Badges/Tags: 4px
- Modals: 12px (larger for emphasis)

### Shadow Usage (Minimal)

- Only use on elevated elements (modals, dropdowns)
- Prefer subtle borders over shadows
- Shadow color: `rgba(0, 0, 0, 0.3)` for depth on dark bg

### Accessibility Requirements

- Maintain WCAG AA contrast (4.5:1 for normal text)
- Cream (#F6F1EB) on espresso (#1B1A17) = 12.56:1 ✅
- Deshojo (#B93E3E) on espresso = needs testing
- Add focus rings (deshojo glow) on all interactive elements
- Ensure all icons have aria-labels

### Responsive Breakpoints

- Mobile: < 768px
- Tablet: 768px - 1024px
- Desktop: > 1024px
- Wide: > 1440px

---

## Delivery Format Preference

**Request: Individual files with clear paths**

Please provide:

1. Complete file contents with full paths (not ZIP)
2. Clear instructions for where each file goes
3. Migration notes for existing components
4. Before/After examples for key components

This way I can:

- Review each change individually
- Test incrementally
- Commit changes with clear messages
- Roll back specific changes if needed

---

## Priority Order for Implementation

1. **High Priority (MVP Branding):**
   - tailwind.config.js
   - application.css base styles
   - Google Fonts integration
   - Main layout nav/footer dark mode
   - Button component classes
   - Shop page product cards

2. **Medium Priority (Complete Experience):**
   - Hero section styling
   - Devise auth pages
   - Cart/checkout pages
   - Admin theme conversion

3. **Polish (Post-Launch Refinements):**
   - Cultivar icon integration
   - Stripe branding config
   - Product detail pages
   - Dashboard components

---

## Files You'll Need to Modify

### Config Files

- `config/tailwind.config.js` (CREATE NEW)

### Stylesheets

- `app/assets/stylesheets/application.css` (UPDATE)

### Layouts

- `app/views/layouts/application.html.erb` (UPDATE - add fonts, logo)
- `app/views/layouts/admin.html.erb` (UPDATE - espresso theme)

### Key Views to Update (Priority Order)

1. `app/views/shop/index.html.erb` (product grid)
2. `app/views/pages/home.html.erb` (hero, CTAs)
3. `app/views/shop/checkout.html.erb` (cart)
4. `app/views/devise/sessions/new.html.erb` (sign in)
5. `app/views/devise/registrations/new.html.erb` (sign up)

### Asset Placeholders Needed

- `app/assets/images/brand/logo.svg` (white maple leaf)
- `app/assets/images/brand/logo-dark.svg` (dark variant)
- `app/assets/images/brand/cultivar-icons/` (4 SVG icons)

---

## Notes for Design Bot

- App is live in production, so we'll test locally first
- We have RSpec tests, so breaking changes will be caught
- GitHub Actions runs tests on every commit
- Prefer gradual rollout over big-bang rewrite
- Keep existing Tailwind utility approach (no custom CSS classes unless reusable)

---

**Ready for your deliverables!** 🎨

Please provide complete file contents with clear paths, and I'll implement them step by step.
