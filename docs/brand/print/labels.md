# Packaging Labels (Print)

This doc is the print-side counterpart to the web style guide.

## What we’re designing for

- Coffee bag labels (front label at minimum)
- Potentially: back label (brew notes, origin, roast date, legal)

## Required inputs (fill these in)

These are the things a printer will ask for.

- Label **finished size** (W × H): TBD
- **Bleed**: TBD (common: 0.125" / 3mm)
- **Safe area**: TBD (common: 0.125" / 3mm inside trim)
- **Corner radius** (if die-cut): TBD
- Material: TBD (paper / matte / gloss / waterproof)
- Adhesive: TBD
- Print process: TBD (digital / offset / letterpress)
- Spot colors? TBD (only if you’re doing specialty printing)

## Color management

- Web colors (RGB/hex) do not automatically equal print colors.
- Ask printer whether they want:
  - CMYK values provided by you, or
  - they will manage conversion from a provided PDF

## File formats

Deliverables you should plan to produce:

- `PDF` (vector, print-ready) — primary
- `PNG` (proof) — optional but useful

If the design includes photos/textures:

- confirm required DPI (commonly 300 DPI at final size)

## Export checklist (printer-safe)

- Document size includes bleed
- Text is inside safe area
- Fonts embedded or outlined (per printer)
- Images are high-resolution
- Colors are correct (CMYK/spot as required)
- Black text uses rich black only if printer recommends it

## Naming convention

Keep exports deterministic so you can reprint later.

Example:

- `acer-label-front_v01_2025-12-31.pdf`
- `acer-label-front_v01_2025-12-31.png`

## Brand consistency checks

Before sending to print:

- Logo stroke weight still reads at the final physical size
- Deshojo red is not too dark/muddy in CMYK conversion
- Cream text is legible if printed (if printing on dark stock)
