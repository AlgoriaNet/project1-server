# Developer Purchase Backend Setup

## Overview

This document explains the `dev_purchase` WebSocket action that enables testing IAP flows in the Unity Editor without real payment processing.

**IMPORTANT:** This action only works in development environment and is protected by device ID validation.

---

## Safety Features

✅ **Development Environment Only** - `Rails.env.development?` check prevents production access
✅ **Device ID Protection** - Only the developer device (7C52EB7B-B58D-51CF-B567-7B6CD124188D) can use this
✅ **Explicit Logging** - All dev purchases logged prominently with `[DEV_PURCHASE]` prefix
✅ **Fail-Safe Design** - Returns 403 error with logging if either safety check fails
✅ **Reuses Existing Code** - Uses tested Purchase and PurchaseCallback classes

---

## Implementation

### File Location

**File:** `app/channels/purchase_channel.rb` (Lines 101-170)

### Action Definition

```ruby
def dev_purchase(json)
  _json = JSON.parse(json['json'])

  # SAFETY CHECK 1: Development environment only
  unless Rails.env.development?
    Rails.logger.error "[DEV_PURCHASE] BLOCKED: Attempted in #{Rails.env}"
    return render_error "dev_purchase", json, "Only in development", 403
  end

  # SAFETY CHECK 2: Device ID validation
  device_id = _json['device_id']
  unless device_id == "7C52EB7B-B58D-51CF-B567-7B6CD124188D"
    Rails.logger.error "[DEV_PURCHASE] BLOCKED: Invalid device ID"
    return render_error "dev_purchase", json, "Invalid device", 403
  end

  # Create order (same as payment action)
  order = Purchase.new(params[:user_id], {
    "product_id" => _json['product_id'],
    "platform" => "unity",  # Skip validation
    "is_sandbox" => true
  }).process

  # Process callback (same as callback action)
  callback_params = {
    "order_id" => order.order_id,
    "platform_order_id" => "dev_purchase_#{SecureRandom.hex(8)}",
    "receipt_data" => nil
  }

  reward_items = PurchaseCallback.new(params[:user_id], callback_params).callback

  # Return response
  render_response "dev_purchase", json, {
    order_id: order.order_id,
    rewards: reward_items,
    Player: Player.find(params[:user_id]).as_ws_json
  }
end
```

---

## How It Works

### Request Format

```json
{
  "action": "dev_purchase",
  "json": "{
    \"product_id\": \"hero_99\",
    \"device_id\": \"7C52EB7B-B58D-51CF-B567-7B6CD124188D\",
    \"is_editor_test\": true
  }"
}
```

### Response Format

**Success (200):**
```json
{
  "type": "dev_purchase",
  "result": {
    "order_id": "order_abc123def456",
    "rewards": {
      "diamond": 99
    },
    "Player": {
      "id": 123,
      "diamond": 1599,
      "gold": 5000,
      ...
    }
  }
}
```

**Failure (403):**
```json
{
  "type": "dev_purchase",
  "error": "Invalid device ID for dev purchase"
}
```

### Execution Flow

```
1. Frontend sends dev_purchase action
   ↓
2. Backend parses JSON
   ↓
3. Check: Rails.env.development? (must be true)
   ├─ If false: Return 403 error and log
   ↓
4. Check: device_id == DEVELOPER_DEVICE_ID
   ├─ If false: Return 403 error and log
   ↓
5. Create order using Purchase.process
   └─ Same as real payment action
   └─ Saves order with status: "pending"
   ↓
6. Process callback using PurchaseCallback.callback
   └─ Same as real callback action
   └─ Uses platform: "unity" to skip receipt validation
   └─ Calls ProductDeliverer to award items
   └─ Updates order status to: "paid"
   ↓
7. Return response with Player object
   └─ Frontend updates local state
```

---

## Key Details

### Platform: "unity"

The `dev_purchase` action uses `platform: "unity"` which:
- Already exists in the system (not new)
- Skips AppStore/Google Play receipt validation
- Is used for development testing by Unity IAP system

From `app/service/purchase_callback.rb` line 61-62:
```ruby
when 'unity'
  # No validation needed for unity platform
```

### Reused Components

The `dev_purchase` action reuses existing, tested components:

| Component | Purpose | Safety |
|-----------|---------|--------|
| `Purchase.new.process` | Create order | Well-tested, used for real purchases |
| `PurchaseCallback.new.callback` | Award items | Well-tested, used for real purchases |
| `ProductDeliverer` | Distribute rewards | Well-tested, used for all purchases |
| `render_response` | Format response | Standard helper, no changes |

**No new business logic is introduced.** The action simply chains existing tested methods.

---

## Logging

### Prominent Logging

All dev purchases are logged with visual separators:

```
============================================================
[DEV_PURCHASE] DEVELOPER PURCHASE INITIATED
[DEV_PURCHASE] Player ID: 123
[DEV_PURCHASE] Product ID: hero_99
[DEV_PURCHASE] Device ID: 7C52EB7B-B58D-51CF-B567-7B6CD124188D
[DEV_PURCHASE] Editor Test: true
[DEV_PURCHASE] Timestamp: 2025-11-24 14:30:00 UTC
============================================================
[DEV_PURCHASE] Order created: order_abc123def456
[DEV_PURCHASE] Purchase completed successfully
[DEV_PURCHASE] Rewards: {"diamond"=>99}
```

### Error Logging

Failed attempts are logged as errors:

```
[DEV_PURCHASE] BLOCKED: Attempted dev_purchase in production environment
[DEV_PURCHASE] BLOCKED: Invalid device ID: different_device_id
[DEV_PURCHASE] ERROR: Product not found - standard error message
```

---

## Testing Scenarios

### Scenario 1: Valid Developer Purchase

```
Device: 7C52EB7B-B58D-51CF-B567-7B6CD124188D
Environment: development
Product: hero_99
Result: ✅ Success - 99 diamonds added, order created
Logs: [DEV_PURCHASE] messages visible
```

### Scenario 2: Wrong Device ID

```
Device: different_device_id_here
Environment: development
Result: ❌ Blocked - 403 error returned
Logs: [DEV_PURCHASE] BLOCKED: Invalid device ID
```

### Scenario 3: Production Environment

```
Environment: production
Device: 7C52EB7B-B58D-51CF-B567-7B6CD124188D
Result: ❌ Blocked - 403 error returned
Logs: [DEV_PURCHASE] BLOCKED: Attempted in production
```

---

## Database Changes

### Orders Table

A new order is created with:
```ruby
Order.create(
  player_id: 123,
  order_id: "order_abc123def456",
  product_id: "hero_99",
  platform: "unity",
  is_sandbox: true,
  status: "paid",
  deliver_time: Time.current
)
```

The order is fully recorded for:
- Audit trail
- FirstCharge day tracking
- Purchase history
- Multi-day feature testing

### Player Table

Player diamonds are updated:
```ruby
Player.find(123).update(diamond: 1599)  # previous + 99
```

This is a real update, persisted to database.

---

## Testing with This Feature

### FirstCharge Multi-Day Testing

```
Day 1:
  1. Click purchase button
  2. dev_purchase creates order
  3. Diamonds awarded
  4. Can immediately claim Day 1

Day 2:
  1. Wait for next calendar day
  2. Day 2 becomes claimable
  3. Click claim Day 2 button
  4. Backend verifies order exists (created by dev_purchase)
  5. Rewards granted

Day 3:
  1. Wait for day after next
  2. Day 3 becomes claimable
  3. Click claim Day 3 button
  4. All rewards claimed
```

All this works because the order is **actually created in the database** by `dev_purchase`.

---

## Monitoring

### How to Monitor Dev Purchases

1. **Console Logs**
   - Watch Rails server logs during test
   - Search for `[DEV_PURCHASE]` prefix
   - Look for visual separator lines

2. **Database Check**
   ```sql
   SELECT * FROM orders WHERE platform = 'unity' AND is_sandbox = true ORDER BY created_at DESC;
   ```

3. **Player Updates**
   ```sql
   SELECT diamond FROM players WHERE id = 123;
   ```

---

## Rollback/Cleanup

### If You Need to Undo a Dev Purchase

```sql
-- Find the dev purchase order
SELECT * FROM orders WHERE order_id LIKE 'order_%' AND platform = 'unity' ORDER BY created_at DESC LIMIT 1;

-- If you need to revert diamonds (run as transaction):
BEGIN;
  DELETE FROM orders WHERE id = <order_id>;
  UPDATE players SET diamond = <previous_amount> WHERE id = <player_id>;
COMMIT;
```

**Note:** This is only for development/testing. Never needed in production.

---

## Security Summary

| Check | Implementation | Effect |
|-------|----------------|--------|
| Environment | `Rails.env.development?` | Blocks production use |
| Device ID | Hardcoded constant match | Blocks other devices |
| Logging | Prominent [DEV_PURCHASE] prefix | Auditable trail |
| Code Reuse | Uses tested Purchase/Callback | No new logic |
| Error Handling | Explicit 403 with error message | Fail-safe |

---

## Future Enhancements

Possible improvements (but not needed now):

1. Configurable device IDs (support multiple developers)
2. Time override for testing Day 2/Day 3 without waiting
3. Batch dev purchases for stress testing
4. Dev purchase report endpoint

---

## Questions?

If you encounter issues:
1. Check Rails server logs for `[DEV_PURCHASE]` messages
2. Verify device ID matches: `7C52EB7B-B58D-51CF-B567-7B6CD124188D`
3. Confirm environment is development mode
4. Check order was created: `SELECT * FROM orders WHERE platform = 'unity'`
5. Check player diamonds updated: `SELECT diamond FROM players WHERE id = <player_id>`
