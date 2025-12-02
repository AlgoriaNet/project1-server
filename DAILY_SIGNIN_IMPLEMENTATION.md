# Daily Sign-In System - Backend Implementation

## Overview
Complete daily sign-in system with 30-day rolling cycles, rewards, milestones, and reclaim functionality.

## Files Created

### Models
1. `/Volumes/WD_SSD/UnityProjects/Rogue/project1-server/app/models/daily_signin_reward.rb`
   - Stores reward configuration for all 30 days
   - Validates day numbers (1-30) and reward types
   - Helper methods for milestone checking

2. `/Volumes/WD_SSD/UnityProjects/Rogue/project1-server/app/models/daily_signin_claim.rb`
   - Tracks which days players have claimed in each cycle
   - Records whether claim was regular or reclaimed (via diamonds)
   - Stores rewards_json for skillbook distributions

3. `/Volumes/WD_SSD/UnityProjects/Rogue/project1-server/app/models/daily_signin_milestone.rb`
   - Tracks milestone claims (days 7, 14, 21, 30)
   - Ensures milestones can only be claimed once per cycle

### Migrations
1. `/Volumes/WD_SSD/UnityProjects/Rogue/project1-server/db/migrate/20251202000001_create_daily_signin_tables.rb`
   - Creates 3 tables: daily_signin_rewards, daily_signin_claims, daily_signin_milestones
   - Adds proper indexes and foreign keys

2. `/Volumes/WD_SSD/UnityProjects/Rogue/project1-server/db/migrate/20251202000002_add_signin_columns_to_players.rb`
   - Adds signin tracking columns to players table:
     - signin_cycle_number (current cycle)
     - signin_first_date (first time player accessed system)
     - signin_last_claim_date (last daily claim date)
     - signin_consecutive_days (consecutive day counter)

### Channel
1. `/Volumes/WD_SSD/UnityProjects/Rogue/project1-server/app/channels/daily_signin_channel.rb`
   - WebSocket methods for frontend communication
   - Methods: get_rewards_config, get_signin_status, claim_daily_signin, reclaim_daily_signin, claim_milestone

### Seeds
1. `/Volumes/WD_SSD/UnityProjects/Rogue/project1-server/db/seeds/daily_signin_rewards.rb`
   - Populates all 30 days of reward configurations
   - Odd days: 200 gold coin
   - Even days: 50 random skillbooks
   - Milestones: Day 7 (30 diamonds), Day 14 (10 epicKey), Day 21 (10 epicKey), Day 30 (10 heroKey + 10 rareKey + 10 epicKey)

## Reward Configuration

### Regular Days
- **Odd days (1, 3, 5, 9, 11, 13, 15, 17, 19, 23, 25, 27, 29)**: 200 gold coin
- **Even days (2, 4, 6, 8, 10, 12, 16, 18, 20, 22, 24, 26, 28)**: 50 random skillbooks
  - 10 different skillbooks randomly selected from IDs 01-20
  - Distributed randomly (not evenly) totaling 50

### Milestone Days
- **Day 7**: 30 diamonds
- **Day 14**: 10 epicKey
- **Day 21**: 10 epicKey
- **Day 30**: 10 heroKey + 10 rareKey + 10 epicKey

## Player Model Methods

Added to `/Volumes/WD_SSD/UnityProjects/Rogue/project1-server/app/models/player.rb`:

### Core Methods

1. **Player.generate_random_skillbooks**
   - Class method that generates random skillbook distribution
   - Returns hash: `{ "Skb_02" => 5, "Skb_07" => 8, ... }`
   - Selects 10 different skillbooks from IDs 01-20
   - Distributes 50 quantity randomly (not evenly)

2. **claim_daily_signin!**
   - Claims today's daily sign-in
   - Automatically advances to next day in cycle
   - If all 30 days completed, advances to next cycle
   - Awards rewards based on day type
   - Updates consecutive_days counter
   - Logs detailed reward information
   - Returns: `{ day_claimed: 5, rewards: {...} }`

3. **reclaim_daily_signin!(day_number)**
   - Allows player to reclaim a missed day
   - Costs 20 diamonds
   - Can fill gaps in sign-in calendar
   - Marks claim as "reclaimed" in database
   - Returns: `{ day_reclaimed: 3, rewards: {...}, diamonds_spent: 20 }`

4. **claim_milestone!(milestone_day)**
   - Claims milestone reward (7, 14, 21, or 30)
   - Requires player to have claimed >= milestone_day regular days
   - Can only be claimed once per cycle
   - Awards milestone-specific rewards
   - Returns: `{ milestone_claimed: 7, rewards: {...} }`

5. **signin_status**
   - Returns complete status object:
   ```ruby
   {
     cycle_number: 1,
     first_date: "2025-12-01",
     last_claim_date: "2025-12-02",
     consecutive_days: 2,
     claimed_days: [1, 2, 3, 5],
     claimed_milestones: [7],
     next_claimable_day: 4,
     claimed_today: false,
     days_claimed_count: 4,
     available_unclaimed_milestones: [14]
   }
   ```

### Helper Methods

- **initialize_signin_if_needed**: Auto-initializes on first access
- **claimed_signin_today?**: Checks if already claimed today
- **next_signin_day**: Returns next available day in cycle

## WebSocket Channel Methods

### get_rewards_config
```json
Request: {}
Response: {
  "success": true,
  "rewards": [
    {
      "day_number": 1,
      "reward_type": "gold_coin",
      "gold_coin": 200,
      "skillbook_count": 0,
      "diamond": 0,
      "epic_key": 0,
      "hero_key": 0,
      "rare_key": 0
    },
    ...
  ]
}
```

### get_signin_status
```json
Request: {}
Response: {
  "success": true,
  "status": {
    "cycle_number": 1,
    "claimed_days": [1, 2, 3],
    "claimed_milestones": [],
    "next_claimable_day": 4,
    "claimed_today": false,
    "days_claimed_count": 3,
    "consecutive_days": 3,
    "available_unclaimed_milestones": []
  }
}
```

### claim_daily_signin
```json
Request: {}
Response: {
  "success": true,
  "day_claimed": 4,
  "rewards": {
    "skillbooks": {
      "Skb_02": 5,
      "Skb_07": 8,
      "Skb_11": 3,
      ...
    }
  },
  "player": { ... }
}
```

### reclaim_daily_signin
```json
Request: {
  "day_number": 5
}
Response: {
  "success": true,
  "day_reclaimed": 5,
  "rewards": {
    "gold_coin": 200
  },
  "diamonds_spent": 20,
  "player": { ... }
}
```

### claim_milestone
```json
Request: {
  "milestone_day": 7
}
Response: {
  "success": true,
  "milestone_claimed": 7,
  "rewards": {
    "diamond": 30
  },
  "player": { ... }
}
```

## Database Schema

### daily_signin_rewards
- day_number (1-30, unique)
- reward_type (gold_coin, skillbooks, milestone)
- gold_coin
- skillbook_count
- diamond
- epic_key
- hero_key
- rare_key

### daily_signin_claims
- player_id (foreign key)
- cycle_number
- day_number (1-30)
- reclaimed (boolean)
- claimed_at
- rewards_json (stores skillbook distribution)
- Unique index: [player_id, cycle_number, day_number]

### daily_signin_milestones
- player_id (foreign key)
- cycle_number
- milestone_day (7, 14, 21, or 30)
- claimed_at
- Unique index: [player_id, cycle_number, milestone_day]

### players (added columns)
- signin_cycle_number (default: 1)
- signin_first_date
- signin_last_claim_date
- signin_consecutive_days (default: 0)

## Setup Instructions

1. Run migrations:
```bash
cd /Volumes/WD_SSD/UnityProjects/Rogue/project1-server
bundle exec rails db:migrate
```

2. Run seeds:
```bash
bundle exec rails runner "load 'db/seeds/daily_signin_rewards.rb'"
```

3. Verify configuration:
```bash
bundle exec rails runner "puts DailySigninReward.count # Should be 30"
```

## Testing Flow

1. Player claims day 1 (odd) -> receives 200 gold coin
2. Player claims day 2 (even) -> receives 50 random skillbooks
3. Player continues to day 7 -> can claim milestone (30 diamonds)
4. Player misses day 8 -> can reclaim for 20 diamonds
5. Player reaches day 30 -> claims final milestone -> cycle advances to 2

## Logging

All operations log detailed information:
- Daily claims: `"Player 123 claimed day 5: 200 gold coin"`
- Skillbook claims: `"Skillbooks awarded: Skb_02=5, Skb_07=8, ... (total 50)"`
- Reclaims: `"Player 123 reclaimed day 5 for 20 diamonds: 200 gold coin"`
- Milestones: `"Player 123 claimed milestone day 7: {:diamond=>30}"`

## Error Handling

All methods raise ArgumentError with clear messages:
- "Already claimed sign-in today"
- "Day number must be between 1 and 30"
- "Day X already claimed"
- "Not enough diamonds (need 20)"
- "Must claim at least X days before claiming this milestone"
- "Milestone day must be 7, 14, 21, or 30"

## Implementation Notes

1. **Cycle Advancement**: Automatically advances to next cycle when day 30 is completed
2. **Random Distribution**: Skillbooks are truly random, not evenly distributed
3. **Transaction Safety**: All operations use database transactions
4. **Auto-initialization**: System initializes automatically on first access
5. **Today Check**: Uses Date.current for timezone-safe date comparison
6. **Milestone Independence**: Milestones are claimed separately from daily claims
7. **Reclaim Tracking**: System tracks which days were reclaimed vs regular claims

## Frontend Integration

The frontend should:
1. Call `get_rewards_config` once on app start to display reward calendar
2. Call `get_signin_status` when opening sign-in UI
3. Call `claim_daily_signin` when player clicks daily claim button
4. Call `reclaim_daily_signin` when player wants to fill a gap
5. Call `claim_milestone` when milestone becomes available
6. Update UI based on `claimed_days` and `claimed_milestones` arrays
7. Show/hide claim button based on `claimed_today` flag

## Future Enhancements

Potential additions (not implemented):
- Push notifications for unclaimed days
- Visual animations for skillbook reveals
- Streak bonuses for consecutive claims
- Special rewards for completing multiple cycles
