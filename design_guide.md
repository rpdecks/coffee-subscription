# Coffee Subscription Website — Design Guide

This document synthesizes the best design patterns from leading coffee subscription companies
(Blue Bottle, Trade, Onyx, Atlas) into a unified guide for the **Cumbre Coffee** brand.

Use this when designing pages, UX flows, and front-end components.

---

## 1. Design Principles

### Minimal & Calm (Blue Bottle influence)

- White space is a feature, not a gap.
- Typography-led layout; avoid heavy ornamentation.
- One main CTA per page.
- Strong brand storytelling without clutter.

### Guided & Personalized (Trade influence)

- Simple onboarding flow for subscriptions.
- Clear "How it works" steps repeated often.
- Preferences (roast level, frequency) presented as simple choices.

### Craft-Focused, Flexible Options (Onyx influence)

- Clear roast info, tasting notes, and origin details.
- Support for multiple bag sizes and delivery cadences.
- Linear, structured decision flow:  
  **Select Coffee → Select Amount → Select Frequency**

### Journey & Experience (Atlas influence)

- Each shipment feels like a moment or story.
- Flavor notes and brewing suggestions provided visually.
- Reinforce the “ascent / summit / cumbre” metaphor.

---

## 2. Core Pages & Purpose

### Homepage

**Goal:** Introduce brand, route user to subscriptions or single-bag shopping.

**Structure:**

1. **Hero Section**

   - Clean visual, minimal text.
   - Tagline: “Cumbre Coffee — Rising to the Summit of Flavor”
   - CTAs:
     - **Start a Subscription**
     - **Shop Single Bags**

2. **Brand Story (Short)**

   - A couple of sentences about craftsmanship, small-batch roasting, and the “summit” metaphor.

3. **Featured Coffees**

   - 2–3 rotating coffees with minimal cards.

4. **How It Works (Trade style)**

   - Three steps with simple icons:
     1. Choose your roast & cadence
     2. Roasted fresh
     3. Delivered on your schedule

5. **Newsletter / Offers**
   - Soft capture for email.

---

## 3. Subscription Flow (Primary UX)

### Step 1: Subscription Landing Page

**Purpose:** Explain subscription benefits simply.

**Key components:**

- Short value statement (“Freshly roasted, delivered on your schedule”).
- Benefits:
  - Pause, skip, or cancel anytime
  - Freshly roasted each cycle
  - Curation based on your preferences
- CTA to “Choose a Plan”

### Step 2: Plan Selection (Onyx structure)

Offer 1–3 core plans:

1. **Roaster’s Choice (flagship)**
2. **House Blend**
3. **Decaf (Swiss Water Process)**

Each plan card includes:

- Name + short description
- Tasting profile
- Price per delivery
- Delivery frequency (weekly / biweekly / monthly)
- Quick CTA: “Customize”

### Step 3: Customize Plan

Linear layout:

**1. Choose Your Bag Size**

- 12 oz
- 2 lb
- (optional) 5 lb

**2. Choose Frequency**

- Weekly
- Every 2 weeks
- Monthly

**3. Whole Bean vs Ground**

**4. Optional Preferences (Trade-style)**

- Roast level
- Brew method
- “Comforting” → “Adventurous” slider

**CTA:** Start Subscription (goes to checkout)

### Step 4: Checkout (Stripe Checkout or custom)

- Minimal fields
- Reinforce next roast/shipping date
- Show price + cadence clearly

---

## 4. Account / Dashboard UX

### Dashboard Overview

**Sections:**

- Next shipment date
- Current subscription plan
- Upcoming coffees (if applicable)
- Quick actions:
  - Pause
  - Skip next delivery
  - Change bag size
  - Change frequency
  - Update grind preference
  - Cancel subscription

### Subscription Details Page

- Billing summary
- Shipment history
- Coffee tasting notes (past orders)
- Address and payment methods

### Tone & UX Priorities

- State changes should be _non-punitive_ (no surprise restrictions).
- Use clear explanation text:
  - “Pausing stops deliveries but preserves your settings.”
  - “You can always return later.”

---

## 5. Visual Style Guide (High-Level)

### Colors

- Neutral base colors (whites, off-whites, very light grays)
- Accent color: deep earthy brown or muted botanical green
- Secondary accent: gold or soft copper for “summit” metaphor

### Typography

- Sans-serif primary (clean, modern, approachable)
- Serif secondary for headings (optional; evokes craft)

### Imagery

- Beans, brewing, and process shots kept subtle and natural.
- Avoid loud palettes or busy backgrounds.
- Occasional landscape or mountain/summit imagery (subtle, not cheesy).

### Layout Pattern

- Max width ~ 1200px
- Generous padding (24–48px sections)
- Modular cards with soft shadow or border

---

## 6. Brand Voice & Copy Guidelines

### Attributes

- Grounded
- Warm
- Expert without being elitist
- Reflective (journey, ascent, ritual)

### Phrases to use regularly

- “Small batch”
- “Freshly roasted”
- “Steady ascent”
