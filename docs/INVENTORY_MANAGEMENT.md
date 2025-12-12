# Inventory Management System

## Overview

The inventory management system tracks your coffee and merchandise inventory with detailed granularity. For coffee products, you can track three distinct states: **Green** (unroasted beans), **Roasted**, and **Packaged**. For merchandise, inventory is tracked as packaged units.

## Key Features

### 1. Multi-State Coffee Tracking

Coffee inventory is tracked in three states:

- **Green**: Unroasted green coffee beans (tracked in pounds)
- **Roasted**: Freshly roasted coffee (tracked in pounds with roast date)
- **Packaged**: Ready-to-ship packaged coffee (tracked in pounds/units)

### 2. Product Show Page Integration

Each product show page in the admin displays:

- **Coffee Products**: Breakdown of green, roasted, and packaged inventory
  - Visual cards showing each state with quantities
  - Total inventory across all states
  - Fresh roasted inventory indicator (within 3 weeks)
  - Low stock alerts
- **Merchandise**: Simple inventory count with low stock alerts

### 3. Dedicated Inventory Tab

Access the full inventory management interface at `/admin/inventory`:

#### Summary Dashboard

- Total items count
- Low stock items (≤5 lbs/units)
- Items expiring soon (within 14 days)
- Out of stock items

#### Filtering & Sorting

- **Search**: By product name or lot number
- **Product Type**: Coffee or Merchandise
- **State**: Green, Roasted, or Packaged
- **Stock Status**: Available, Low Stock, Out of Stock, Expiring Soon
- **Sort Options**:
  - Newest first
  - Quantity (low to high / high to low)
  - Roast date
  - Received date

#### Inventory Table

Displays:

- Product name and type
- State (with color-coded badges)
- Quantity in pounds/units
- Lot number
- Important dates (received, roasted, expires)
- Freshness indicator for roasted coffee
- Edit/Delete actions

### 4. Freshness Tracking

For roasted coffee, the system automatically tracks freshness:

- **Fresh** (0-7 days): Green badge
- **Good** (8-21 days): Yellow badge
- **Aging** (22+ days): Gray badge

### 5. Inventory Operations

#### Adding Inventory

1. Click "Add Inventory" button
2. Select product
3. Choose state (green/roasted/packaged)
4. Enter quantity in pounds
5. Optional: Add lot number, dates, notes
6. Save

#### Editing Inventory

- Update quantities as inventory changes
- Adjust dates when roasting green coffee
- Add notes for tracking purposes

#### Tracking Green → Roasted

When roasting green coffee:

1. Reduce green inventory quantity
2. Create new roasted inventory entry with roast date
3. System automatically calculates freshness

## Database Schema

### InventoryItem Model

```ruby
create_table :inventory_items do |t|
  t.references :product, null: false, foreign_key: true
  t.integer :state, null: false, default: 0  # 0: green, 1: roasted, 2: packaged
  t.decimal :quantity, precision: 10, scale: 2, null: false, default: 0.0
  t.string :lot_number
  t.date :roasted_on
  t.date :received_on
  t.date :expires_on
  t.text :notes
  t.timestamps
end
```

### Product Extensions

New methods added to Product model:

- `total_green_inventory` - Sum of green coffee pounds
- `total_roasted_inventory` - Sum of roasted coffee pounds
- `total_packaged_inventory` - Sum of packaged inventory
- `total_inventory_pounds` - Grand total across all states
- `low_on_inventory?(threshold)` - Check if below threshold
- `fresh_roasted_inventory` - Amount of fresh roasted coffee (≤21 days)

## Workflow Examples

### Example 1: Receiving Green Coffee

1. Navigate to Inventory tab
2. Click "Add Inventory"
3. Select your coffee product (e.g., "Ethiopia Yirgacheffe")
4. State: Green
5. Quantity: 50.0 lbs
6. Lot Number: LOT2024-001
7. Received Date: Today
8. Notes: "Direct trade, natural process"
9. Save

### Example 2: Roasting Coffee

When you roast 10 lbs of green coffee:

1. Edit the green inventory item, reduce quantity by 10 lbs
2. Add new inventory item:
   - Same product
   - State: Roasted
   - Quantity: 9.0 lbs (accounting for weight loss)
   - Roasted Date: Today
   - Expires: 3 weeks from today
   - Lot Number: Same as green coffee lot

### Example 3: Palmatum Blend Management

Your Palmatum blend (signature roast) is made from multiple products:

**Current Approach:**

- Track individual green coffee inventories
- When creating Palmatum blend, reduce quantities from source products
- Create roasted Palmatum inventory entry with the blend components noted

**Future Enhancement Idea:**
You could add a `blend_components` table to formally track which products make up each blend with ratios.

### Example 4: Monitoring Freshness

Use filters to monitor coffee freshness:

1. Filter by "Expiring Soon" to see roasted coffee approaching 3 weeks
2. Sort by "Roast Date" to prioritize older roasted inventory
3. View freshness badges to quickly identify aging coffee

## Best Practices

1. **Regular Updates**: Update inventory quantities as you roast, package, and ship
2. **Lot Tracking**: Always use lot numbers for traceability
3. **Date Accuracy**: Enter accurate roast dates to leverage freshness tracking
4. **Low Stock Monitoring**: Check the dashboard regularly for low stock alerts
5. **Expiry Management**: Set expiry dates for roasted coffee (typically 21-30 days)

## Future Enhancements

Consider adding:

- Automated inventory deduction when orders ship
- Blend component tracking (for Palmatum and other blends)
- Cost per pound tracking for COGS calculations
- Inventory history/audit log
- Barcode/QR code generation for lot tracking
- Reorder alerts based on average usage
- Integration with roasting equipment for automatic weight capture

## Routes

- Index: `GET /admin/inventory`
- New: `GET /admin/inventory/new`
- Create: `POST /admin/inventory`
- Edit: `GET /admin/inventory/:id/edit`
- Update: `PATCH /admin/inventory/:id`
- Delete: `DELETE /admin/inventory/:id`

## Notes on Legacy `inventory_count` Field

The existing `inventory_count` integer field on the Product model is still in place for backwards compatibility. For coffee products, the granular inventory tracking via InventoryItems is the recommended approach. The `inventory_count` field can be used for simple stock counts or deprecated over time as you transition to the new system.
