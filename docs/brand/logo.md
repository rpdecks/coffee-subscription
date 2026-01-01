# Logo & Icons

## Primary mark

- Primary mark is the Acer maple leaf line-art.
- App uses SVG for crisp scaling.

### Current assets in repo

- `app/assets/images/brand/logo.svg` (primary)
- `app/assets/images/brand/acer-watermark.svg` (background watermark)
- `app/assets/images/brand/cultivar-icons/` (category/cultivar icons)

## Usage rules

### Color

- Default on-site usage assumes dark background: logo in `cream`.
- Avoid placing the logo over busy imagery without a backing surface.

### Clear space

- Maintain clear space around the mark equal to at least the leaf stem thickness (practical rule).
- Never crowd the logo against container edges.

### Minimum sizes (web)

- Nav: 20–28px tall (with consistent baseline alignment)
- Favicons/app icons: use dedicated exports rather than shrinking the full mark too far

## Export requirements

### Web exports

- SVG (primary)
- PNG (fallback, social)
- Favicon set (generated from a single square source)

### Print exports

For bags/labels, prefer:

- Vector PDF (text outlined if required by printer)
- SVG (for internal previews)

## Cultivar icons

Cultivar icons are functional, not decorative.

- Must work at 16–20px (product cards)
- Must have accessible text labels when used as UI controls

## Decisions log

If the icon changes (stroke width, corner joins, simplification), record:

- what changed
- why
- which exports were regenerated
