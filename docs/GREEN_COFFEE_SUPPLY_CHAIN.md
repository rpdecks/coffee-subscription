# Green Coffee Supply Chain

## Overview

The supply chain system separates **what you buy** (green coffee from suppliers) from **what you sell** (your branded products). This enables tracking of supplier relationships, green coffee freshness, blend recipes, and cost analysis.

## Models

### Supplier

Represents a green coffee vendor (e.g., Sweet Maria's, Royal Coffee New York, Cafe Imports).

| Field         | Type   | Notes            |
| ------------- | ------ | ---------------- |
| name          | string | Required, unique |
| url           | string | Supplier website |
| contact_name  | string | Primary contact  |
| contact_email | string | Contact email    |
| notes         | text   | General notes    |

### GreenCoffee

A specific lot or purchase of unroasted green coffee from a supplier.

| Field          | Type    | Notes                              |
| -------------- | ------- | ---------------------------------- |
| supplier_id    | FK      | Required — links to Supplier       |
| name           | string  | Required — e.g., "Altiplano Blend" |
| origin_country | string  | Country of origin                  |
| region         | string  | Growing region                     |
| variety        | string  | e.g., Caturra, Heirloom            |
| process        | string  | e.g., Washed, Natural, Honey       |
| harvest_date   | date    | For freshness tracking             |
| arrived_on     | date    | When received at your location     |
| cost_per_lb    | decimal | Purchase cost per pound            |
| quantity_lbs   | decimal | Current green inventory on hand    |
| lot_number     | string  | Supplier lot reference             |
| notes          | text    | Cupping notes, etc.                |

### BlendComponent

Join table linking Products to GreenCoffees with a percentage (the "recipe").

| Field           | Type    | Notes                |
| --------------- | ------- | -------------------- |
| product_id      | FK      | Your branded product |
| green_coffee_id | FK      | Source green coffee  |
| percentage      | decimal | e.g., 40.0 for 40%   |

Unique index on `[product_id, green_coffee_id]` — each green coffee appears once per product.

## Freshness Tracking

Green coffee freshness is based on months since harvest:

| Status    | Months Since Harvest | Badge Color |
| --------- | -------------------- | ----------- |
| Fresh     | < 6 months           | Green       |
| Good      | 6–10 months          | Yellow      |
| Aging     | 10–12 months         | Orange      |
| Past Crop | > 12 months          | Red         |

Green coffee doesn't "expire" like roasted coffee, but flavor quality degrades over time. Past-crop beans may taste flat or papery.

## Workflow

### 1. Add Suppliers

Navigate to **Admin → Suppliers** and add your vendors:

- Sweet Maria's
- Royal Coffee New York
- Cafe Imports

### 2. Add Green Coffee Purchases

Navigate to **Admin → Green Coffee** and add each lot you purchase:

- Select the supplier
- Enter the coffee name, origin, variety, process
- Set quantity in pounds and cost per pound
- Enter the harvest date (for freshness tracking)
- Enter arrival date (when you received it)
- Optionally add a lot number and notes

### 3. Define Blend Recipes

Go to any coffee Product's admin page (e.g., Palmatum Blend) and use the **Blend Recipe** section to add components:

- Select a green coffee
- Enter the percentage (e.g., 40%)
- Percentages are validated to not exceed 100% total

#### Single Origin Example

Ethiopian Yirgacheffe product → one BlendComponent at 100% pointing to an Ethiopia Guji green coffee from Sweet Maria's.

#### Blend Example

Palmatum Blend → three BlendComponents:

- 40% Sweet Maria's Altiplano Blend
- 30% Ethiopia Guji
- 30% Colombia El Paraiso

### 4. Track Inventory

When you roast, manually reduce `quantity_lbs` on the GreenCoffee record. The existing InventoryItem system (roasted/packaged states) continues to track the Product-level inventory after roasting.

### 5. Monitor Freshness

The Green Coffee index page shows freshness badges for each lot. Filter by freshness status to identify aging or past-crop beans that should be prioritized or replaced.

## Admin Routes

| Path                                            | Action                                |
| ----------------------------------------------- | ------------------------------------- |
| `/admin/suppliers`                              | Supplier list                         |
| `/admin/suppliers/new`                          | Add supplier                          |
| `/admin/suppliers/:id`                          | Supplier detail + their green coffees |
| `/admin/suppliers/:id/edit`                     | Edit supplier                         |
| `/admin/green_coffees`                          | Green coffee inventory list           |
| `/admin/green_coffees/new`                      | Add green coffee                      |
| `/admin/green_coffees/:id`                      | Green coffee detail                   |
| `/admin/green_coffees/:id/edit`                 | Edit green coffee                     |
| `/admin/products/:id/blend_components/new`      | Add component to a product's blend    |
| `/admin/products/:id/blend_components/:id/edit` | Edit blend component                  |

## Relationship to Existing Inventory System

The existing `InventoryItem` model with `green/roasted/packaged` states still works for tracking Product-level inventory (roasted and packaged states). The `GreenCoffee` model replaces the need for `green` state InventoryItems for coffee products, providing richer data about the source beans.

Over time, you may want to deprecate the `green` state on `InventoryItem` in favor of `GreenCoffee.quantity_lbs`.

## Future Enhancements

- **Purchase Orders**: Track orders placed with suppliers (quantity ordered, expected arrival, invoice)
- **Automated roasting deduction**: When recording a roast, auto-reduce green coffee quantities based on blend recipe
- **Cost-per-bag reporting**: Calculate per-product cost using blend percentages and green coffee costs
- **Supplier spend reports**: Total spend per supplier over a time period
- **Reorder alerts**: Notify when green coffee quantities drop below threshold
