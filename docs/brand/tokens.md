# Design Tokens

These are the **approved design tokens** for Acer Coffee.

## Color palette (dark-mode first)

### Semantic names (preferred)

These names match `config/tailwind.config.js`.

- `espresso` — `#1B1A17` (primary background)
- `espresso-light` — `#252320` (table rows / elevated surfaces)
- `cream` — `#F6F1EB` (primary text)
- `deshojo` — `#B93E3E` (primary CTA)
- `coffee-brown` — `#4A2F27` (secondary CTA)
- `moss` — `#78866B` (optional accent)

### Usage rules

- Default page background: `bg-espresso`
- Default text: `text-cream`
- Primary actions (Subscribe, Add to Cart, Checkout): `bg-deshojo text-cream`
- Secondary actions (Manage, Details, neutral actions): `bg-coffee-brown text-cream`
- Tertiary actions (Cancel/Back): cream outline style

### Opacity conventions

- Body text: 85% opacity
- Meta/secondary text: 70% opacity

In Tailwind, prefer utilities like `text-cream/85` and `text-cream/70`.

## Typography

### Font families

These match `config/tailwind.config.js`.

- Headings: `font-serif` (Source Serif 4 fallback to Georgia)
- Headings: `font-serif` (Cormorant Garamond fallback to Georgia)
- Body/UI: `font-sans` (Inter fallback to system-ui)

### Scale (starting point)

This is guidance, not a hard rule.

- H1: `text-5xl`–`text-6xl`, `font-semibold`, `font-serif`
- H2: `text-4xl`, `font-semibold`, `font-serif`
- H3: `text-2xl`–`text-3xl`, `font-semibold`, `font-serif`
- Body: `text-base`, `font-normal`, `font-sans`
- Small/meta: `text-sm`, `font-normal`, `font-sans`, 70% opacity

## Spacing

### Principles

- Prefer generous whitespace; avoid dense UIs.
- Use consistent spacing steps.

### Suggested spacing steps

Use Tailwind’s spacing scale; default to: `2, 3, 4, 6, 8, 10, 12` (i.e. 8px, 12px, 16px, 24px, 32px, 40px, 48px).

## Radius, shadows

### Border radius

These match `config/tailwind.config.js`.

- Buttons/inputs: `rounded-brand` (6px)
- Cards: `rounded-card` (8px)
- Badges: `rounded-badge` (4px)
- Modals: `rounded-modal` (12px)

### Shadows

Minimal. Prefer borders over heavy shadows.

- Elevated elements: `shadow-minimal`

## Focus states (accessibility)

- All interactive elements must have a visible focus ring.
- Prefer a `deshojo`-tinted ring for brand consistency, while keeping contrast.

(Implementation note: we’ll standardize this when we convert components.)
