# CLAUDE.md - Project Knowledge Base

## Project Overview
This is a **Ruby on Rails 7.1.5 backend server** for a Unity-based rogue-like RPG mobile game. The server handles player progression, real-time battles, sidekick collection/upgrades, and monetization systems.

## Quick Start Information

### Technology Stack
- **Framework**: Ruby on Rails 7.1.5 
- **Ruby Version**: 3.0.6
- **Database**: MySQL (not SQLite - check Gemfile)
- **Real-time**: ActionCable WebSockets + Redis
- **Authentication**: JWT tokens
- **Key Gems**: redis-objects, jwt, bcrypt, rack-cors, enumerize, roo

### Development Commands
```bash
# Start server (production uses Puma daemon)
bundle exec rails server -p 3000 -d

# Kill server processes after git reverts (IMPORTANT!)
pkill -f puma

# Run tests (check for specific test commands)
# TODO: Document test framework and commands

# Lint/Typecheck commands
# TODO: Document if any linting tools are configured
```

### Project Structure
```
app/
├── channels/        # WebSocket channels for real-time API
├── controllers/     # HTTP API endpoints
├── models/         # ActiveRecord models
├── service/        # Business logic services
lib/
├── config/         # CSV-based game configuration
├── utils/          # Utility scripts for data management
documentation/      # Project documentation (see below)
```

## Core Game Systems

### 1. Sidekicks System (Primary Feature)
**Purpose**: Players collect and upgrade AI companions for battles

**Key Models**:
- `BaseSidekick`: Templates for 20 unique sidekick types
- `Sidekick`: Player-owned instances with progression data
- `BaseSkillLevelUpEffect`: Upgrade progression definitions

**Important Data Patterns**:
- **API Identifier**: Always use `fragment_name` (e.g., "04_Aurelia") for API calls, NOT numeric IDs
- **Skill Books**: Named as "SKb_" + fragment_name (e.g., "SKb_04_Aurelia") 
- **Star Range**: 0→5, **Level Range**: 1→20
- **New Sidekicks**: Start at star 0, level 1

### 2. Battle System
- Formation-based combat (max 4 sidekicks per team)
- Multiple formations supported (up to 3 sets)
- Equipment and gemstone enhancement system
- Stage-based progression through `MainStage` model

### 3. Economy & Monetization
- **Currencies**: Gold coins, skill books, shards, items (JSON-stored in player)
- **Purchases**: Apple/Google receipt validation system
- **Gacha**: Draw system for acquiring sidekicks
- **Subscriptions**: Monthly/weekly card system

## API Architecture

### Communication Patterns
1. **HTTP REST API**: Basic operations (`/api/login`, `/api/allies/:ally_id/upgrade_levels`)
2. **WebSocket API**: Real-time game actions via ActionCable channels

### Critical API Design Rules
⚠️ **These rules prevent data consistency bugs that cost 100+ hours to debug**

1. **Return Complete State**: Mutating APIs must return complete updated objects, not just deltas
2. **Avoid Secondary API Calls**: Include all related data in primary response
3. **Use Model Serialization**: Always use `as_ws_json` methods for consistent data
4. **Prevent Race Conditions**: Single authoritative response eliminates timing issues

**Example - Correct API Response Pattern**:
```ruby
# ✅ CORRECT: Complete state response
render_response "star_upgrade", json, {
  data: {
    ally_id: ally_name,
    new_star: player_sidekick.star,
    gold: player.gold_coin,
    shards: player.items_json[shard_name]
  },
  updated_sidekick: player_sidekick.as_ws_json  # Complete object
}
```

## Configuration System
Game balance is driven by CSV files in `lib/config/`:
- `base_sidekicks.csv`: Sidekick templates and stats
- `base_skills.csv`: Skill configurations (cooldown, duration, damage, etc.)
- `level_up_costs.csv`: Universal level upgrade costs
- `star_upgrade_costs.csv`: Universal star upgrade costs
- `draw_cost.csv`: Gacha system costs
- And more...

### ⚠️ CRITICAL: CSV-to-Database Update Policy

**🚫 BANNED METHOD - NEVER USE THIS:**
```ruby
# ❌ NEVER EVER RUN THESE GENERATOR SCRIPTS
GenerateBaseSkills.generate      # Destroys ALL skills and skill effects
GenerateBaseEquipment.generate   # Destroys ALL equipment including player items
GenerateBaseSidekicks.generate   # Destroys ALL sidekick templates
# ANY script with .destroy_all is BANNED
```

**Why This Is Banned:**
- Past incidents caused complete data loss (equipment, skills, player progress)
- `destroy_all` has cascading effects that delete player data
- Recovery requires database restoration
- These scripts were designed for initial setup, NOT production updates

**✅ CORRECT METHOD - Direct Database Updates:**
```ruby
# ✅ ALWAYS use surgical database updates for CSV changes
BaseSkill.find(15).update(name: 'NewName', duration: 7.0)
BaseEquipment.find(3).update(display_name: 'New Display Name')
```

**Update Workflow:**
1. Edit CSV file (source of truth)
2. Update specific database record(s) with `.update()`
3. Commit both CSV and note that database was manually synced
4. NEVER run generator scripts in production

**Historical Context:**
- [2025-08-07] GenerateBaseEquipment.generate deleted ALL player equipment
- [2025-10-09] Established policy: Generator scripts are banned in production
- CSV files remain source of truth, but updates must be surgical

## Known Issues & Patterns

### Server Restart After Git Reverts
⚠️ **CRITICAL**: After git reverts, always restart server to clear memory cache:
```bash
git reset --hard <commit>
pkill -f puma  # Kill cached processes
bundle exec rails server -p 3000 -d  # Restart fresh
```

### WebSocket Caching (FIXED)
Player objects were cached in WebSocket connections causing stale inventory data. Fixed by adding `player.reload` calls to WebSocket methods.

### Equipment API Disruption Incident (2025-07-30)
⚠️ **CRITICAL LESSON**: Adding equipment directly to database broke WebSocket APIs

**What Happened**: Added 21 equipment items to player 4 using direct database inserts, which caused:
- WebSocket replace/equip APIs to stop responding completely
- Frontend operations to hang indefinitely  
- Required full server restart to restore functionality

**Root Cause**: WebSocket connections cache player inventory data. Direct database changes bypass this cache, causing:
1. Frontend sees old inventory without new equipment
2. WebSocket channels have stale `@player` objects
3. API calls fail silently due to data inconsistency

**Resolution Required**:
- Server restart: `pkill -f puma && bundle exec rails server -p 3000 -d`
- Added `@player.reload` to equipment channel methods

### Gemstone Data Loss Incident (2025-08-01)
⚠️ **CRITICAL LESSON**: Overly broad `destroy_all` in test scripts deleted embedded gems

**What Happened**: During auto merge verification testing, used `Gemstone.where(player_id: player_id).destroy_all` which deleted:
- ALL gemstones for player 4, including embedded gems on equipment
- Lost embedded gemstone progression data that player had built up
- No WebSocket API disruption (used proper APIs, not direct database inserts)

**Root Cause**: Test cleanup was too broad in scope:
1. Intended to clean up test gems for clean verification
2. Used `destroy_all` on entire player's gemstone collection instead of filtering
3. Did not distinguish between test inventory gems and production embedded gems

**Key Differences from Equipment Incident**:
- **No server restart needed**: Used `Gemstone.generate()` and `save!` (proper APIs)
- **No WebSocket cache issues**: Followed established game patterns
- **Data loss, not API disruption**: Lost existing data but APIs remained functional

**Prevention Measures**:
- Always scope `destroy_all` to specific test data only
- Use filters like `where(is_in_inventory: true, equipment_id: nil)` for test cleanup
- Never use broad `destroy_all` on production player data
- Embedded gems (equipment_id present) should never be touched by test scripts


## Current Development Status

### Completed Systems
- 20 unique sidekick templates with localization
- Player progression and battle formation system
- Equipment/gemstone enhancement
- Payment processing with receipt validation
- WebSocket-based real-time API

### Known TODOs
- Realistic gold costs and skill book requirements need balancing
- Many upgrade effects lack proper descriptions
- Combat stats need balance testing
- Test framework documentation needed
- Linting/code quality tools documentation needed

## CRITICAL: Data Modification Safety Rules

### ⚠️ NEVER Directly Modify Player Data Without These Steps

**Before adding equipment, items, or currency to any player:**

1. **Use Existing APIs First**: Check if there are proper APIs for adding items:
   ```bash
   # Search for existing methods
   grep -r "add.*equipment\|create.*equipment" app/
   grep -r "give.*item\|add.*item" app/
   ```

2. **Test in Isolation**: Always test data changes on a separate player/environment first

3. **Check WebSocket Impact**: Verify if the data affects any WebSocket channels:
   ```bash
   # Find channels that use the data
   grep -r "player.*equipment\|@player" app/channels/
   ```

4. **Mandatory Server Restart**: After ANY direct database modifications:
   ```bash
   pkill -f puma
   bundle exec rails server -p 3000 -d
   ```

5. **Verify API Functionality**: Test all related APIs after data changes:
   - Equipment equip/replace operations
   - Inventory loading
   - Player profile fetching

### Safe Methods for Adding Game Items

**✅ PREFERRED: Use Game APIs**
```ruby
# Use existing service methods or APIs
player.add_equipment(base_equipment_id, attributes)
# OR through proper channels/controllers
```

**⚠️ ACCEPTABLE: Rails Console with Restart**
```ruby
# Only if no APIs exist
Equipment.create!(player_id: X, base_equipment_id: Y, ...)
# MUST restart server immediately after
```

**❌ NEVER: Direct Database INSERT without restart**
```sql
-- This WILL break WebSocket APIs
INSERT INTO equipments ...
```

## Important Files for Analysis
- `documentation/sidekicks_system_memo.md`: Detailed sidekick system architecture
- `documentation/api_design_best_practices.md`: Critical API design lessons
- `documentation/server_troubleshooting.md`: Common server issues
- `config/routes.rb`: API endpoint definitions
- `app/channels/`: WebSocket API implementations
- `lib/config/*.csv`: Game balance configuration

---

## Instructions for Future Agents

### When to Update This Document
You MUST update this CLAUDE.md file when you:

1. **Discover new major systems or components** not documented here
2. **Complete significant implementation work** that other agents should know about
3. **Fix critical bugs** that establish new patterns or best practices
4. **Add new development tools, commands, or workflows**
5. **Identify additional TODOs or technical debt** that needs attention
6. **Learn important lessons** from debugging or development work

### How to Update This Document
1. **Add to relevant sections** - don't just append to the end
2. **Update the "Current Development Status"** section with completed work
3. **Document new TODOs** you discover during your work
4. **Add new "Known Issues & Patterns"** if you encounter significant problems
5. **Update commands/workflows** if you discover better approaches

### Update Format
When updating, add a brief note about what you learned:
```markdown
## Equipment System API

### WebSocket Equipment APIs
Located in `app/channels/equipment_channel.rb`, provides two main operations:

#### 1. `equip` API
**Purpose**: Add equipment to empty slots (no existing equipment removal)

**Request Format**:
```json
{
  "action": "equip",
  "type": "hero|sidekick", 
  "sidekickId": 123,  // Required for sidekick, null for hero
  "equipmentId": 456
}
```

**Behavior**:
- Validates equipment is not already equipped
- Checks if target slot is empty (returns error if occupied)
- Equips to empty slot only
- Returns complete player profile in response

#### 2. `replace` API  
**Purpose**: Swap equipment (removes old equipment + adds new)

**Request Format**:
```json
{
  "action": "replace",
  "type": "hero|sidekick",
  "sidekickId": 123,  // Required for sidekick, null for hero  
  "equipmentId": 456
}
```

**Behavior**:
- Automatically unequips existing equipment in same part
- Equips new equipment
- Works for both occupied and empty slots
- Returns complete player profile in response

### Equipment Data Model
- `Equipment` model supports both Hero and Sidekick via polymorphic associations
- `equip_with_hero_id` and `equip_with_sidekick_id` foreign keys
- Equipment parts prevent multiple items in same slot
- `equipment.equip_with(living)` handles the core logic

### API Response Format
Both APIs follow the established pattern and return complete state:
```json
{
  "action": "equip|replace",
  "code": 200,
  "requestId": "...",
  "data": {
    "type": "hero|sidekick",
    "sidekickId": 123,
    "equipmentId": 456, 
    "success": true
  },
  "player_profile": { /* Complete player profile object */ }
}
```

**Error responses** include descriptive messages and appropriate error codes.

## Washing/Forge System

### Forge API Overview
"Forge" is the main umbrella function containing multiple equipment enhancement operations:
- **enhance/auto_enhance** - Level up equipment (already implemented)
- **wash** - Re-roll equipment attributes with probability-based system (implemented)
- **upgrade** - Quality/tier upgrades (not yet implemented)

### Washing System (Probability-Based)

**Located**: `app/channels/equipment_channel.rb` - `wash` method

**Configuration**: `lib/config/washing_probability_config.csv` (replaces old fixed-count system)

**Probability Rules by Quality**:
- **Quality 1-2**: 100% chance → 1 attribute, values 2-5
- **Quality 3**: 60% → 1 attr, 30% → 2 attr, 10% → 3 attr, values 5-10
- **Quality 4**: 40% → 1 attr, 40% → 2 attr, 20% → 3 attr, values 10-20
- **Quality 5**: 0% → 1 attr, 40% → 2 attr, 60% → 3 attr, values 20-30
- **Quality 6**: 0% → 1 attr, 0% → 2 attr, 100% → 3 attr, values 30-50

**API Request Format**:
```json
{
  "action": "wash",
  "equipmentId": 456
}
```

**Cost**: 200 crystals (non-refundable, not included in dismantle refund calculations)

**Response**: Returns complete player state + old/new attributes for UI comparison

**Equipment Quality Mapping**:
- Equipment names like `Chest_01`, `Helm_01` → Quality 1
- Equipment names like `Chest_02`, `Helm_02` → Quality 2
- And so on through Quality 6

### Implementation Details
- **Probability System**: Uses `rand()` with cumulative probability thresholds
- **No Duplicate Attributes**: Uses array sampling with removal to prevent duplicates
- **Attribute Types**: Different sets for Quality 6+ (includes "All" resistance type)
- **Value Generation**: Random integer within min/max range per quality level

## UI Bug Debugging Best Practices

### 🚨 Critical Rule: "UI Bugs" Are Usually Backend Data Consistency Issues

Most display bugs that appear to be frontend issues are actually **backend race conditions or data inconsistency problems**. Always investigate backend first.

#### Common "UI Bug" Patterns That Are Actually Backend Issues:

**1. Flickering/Changing Colors**
- **Frontend reports**: "Equipment color keeps changing between blue and yellow"
- **Real cause**: Backend API returning inconsistent rank_color values due to race conditions
- **Investigation**: Check if API responses return different data for same equipment ID

**2. Data Appearing/Disappearing** 
- **Frontend reports**: "Gems disappear after equipment replace"
- **Real cause**: Backend not transferring embedded data during operations
- **Investigation**: Verify business logic handles data migration correctly

**3. Stale Data Display**
- **Frontend reports**: "UI shows old values after upgrade"
- **Real cause**: Backend API creating PlayerProfile before completing all operations
- **Investigation**: Check API response timing and data refresh order

#### Race Condition Debugging Methodology:

**Step 1: Verify Database State**
```ruby
# Check what's actually in the database
equipment = Equipment.find(ID)
puts "Database: rank=#{equipment.upgrade_rank}, color=#{equipment.rank_color}"
```

**Step 2: Test API Consistency**  
```ruby
# Test same API multiple times
5.times do |i|
  result = api_call()
  puts "Call #{i}: equipment_id=#{result[:id]}, color=#{result[:rank_color]}"
end
```

**Step 3: Identify Race Conditions**
Look for this dangerous pattern:
```ruby
# ❌ WRONG: PlayerProfile created before equipment operations complete
player_profile = PlayerProfile.new(player_id)  # Queries NOW (stale data)
equipment.reload.as_ws_json                     # Updates LATER (fresh data)
player_profile.as_ws_json                       # Returns OLD data

# ✅ CORRECT: PlayerProfile created after all operations complete  
equipment.reload                                # Ensure fresh data FIRST
player_profile = PlayerProfile.new(player_id)  # Query AFTER operations
```

#### Equipment Data Consistency Critical Fix (2025-08-06):

**Root Cause**: All equipment APIs (enhance, upgrade_rank, wash, auto_enhance) had race conditions where PlayerProfile was created before equipment.reload, causing inconsistent API responses.

**Symptoms**:
- Equipment colors flickering (rank 5 showing as white #FFFFFF instead of blue #87CEEB)
- PlayerProfile returning different equipment data than individual equipment calls
- Users needing logout/login to see correct data

**Solution Applied**:
```ruby
# Fixed in all equipment APIs:
@player.reload                                  # 1. Refresh player
equipment.reload                                # 2. Refresh equipment  
player_profile = PlayerProfile.new(@player_id) # 3. Create profile AFTER refreshes

render_response {
  updated_equipment: equipment.as_ws_json,      # Same fresh data
  player_profile: player_profile.as_ws_json     # Same fresh data
}
```

#### Gem Transfer System Fix (2025-08-06):

**Root Cause**: Gems were tied to equipment instances instead of character equipment slots, causing gem loss during equipment replace operations.

**Solution**: Modified `equip_with` method to transfer gems from old equipment to new equipment:
```ruby
def equip_with(living)
  equipped = living.equipments.select { |eq| eq.base_equipment.part == self.base_equipment.part }
  
  ApplicationRecord.transaction do
    equipped.each do |old_equipment|
      # Transfer gems before unequipping
      old_equipment.gemstones.each do |gem|
        gem.equipment_id = self.id
        gem.save!
      end
      old_equipment.unequip
    end
    # ... rest of equip logic
  end
end
```

#### Prevention Rules:

1. **Always suspect backend first** when frontend reports data display issues
2. **Check API response consistency** by calling same endpoint multiple times  
3. **Verify database state** matches what APIs return
4. **Look for race conditions** in APIs that modify then query data
5. **Use transactions** for complex operations that modify multiple related records
6. **Create aggregated data (PlayerProfile) AFTER individual operations complete**
7. **Reload models** before creating response data to ensure fresh state

#### When "UI Bugs" Are Actually UI Bugs:
- CSS styling issues
- Animation/transition problems  
- Event handling bugs
- Layout/positioning issues
- **NOT data value inconsistencies** - those are backend bugs

## Recent Updates
- [2025-10-09] [POLICY: Generator Scripts Banned]: Established permanent ban on all CSV generator scripts (GenerateBaseSkills, GenerateBaseEquipment, etc.) for production use. All CSV updates must use surgical database .update() calls. Added comprehensive documentation in Configuration System section. Updated Velan's skill from dummy to Skill_PoisonDartVolley (duration 2.0s, 6-dart attack pattern).
- [2025-08-07] [CRITICAL: CSV Display Name Update Disaster]: ⚠️ **NEVER use GenerateBaseEquipment.generate for simple renames**. Contains `Equipment.destroy_all` which deleted ALL player equipment (hero, allies, inventory). For display name changes, use direct SQL UPDATE on base_equipments table only. Cost: Complete equipment data loss across all players.
- [2025-08-06] [Critical Race Condition Fix]: Fixed equipment data inconsistency bug affecting all equipment APIs. PlayerProfile now created after equipment operations complete, eliminating stale data in API responses. Also implemented gem transfer system to preserve gems during equipment replace operations.
- [2025-08-04] [Washing System Redesign]: Implemented probability-based washing system replacing fixed-count approach. Added quality-based probability rules (60%/30%/10% for Quality 3, etc.) with appropriate value ranges. Old `washing_config.csv` marked obsolete. System tested and working with expected probability distributions.
- [2025-07-23] [Equipment API Implementation]: Created dedicated `equip` API for empty slots and enhanced `replace` API with proper error handling and complete state responses. Fixed Sidekick equipment association. Both Hero and Sidekick equipment operations now work correctly with full data consistency.
```

### Example Update
```markdown
## Recent Updates  
- [2025-07-30] [Data Safety Rules]: Added critical prevention measures after equipment addition broke WebSocket APIs. Documented mandatory server restart requirements and safe data modification procedures.
- [2025-07-23] [Initial Analysis]: Created comprehensive project overview and documented core game systems, API patterns, and development workflows.
```

---

*This document serves as the primary knowledge base for Claude agents working on this project. Keep it current and comprehensive to ensure efficient development workflows.*