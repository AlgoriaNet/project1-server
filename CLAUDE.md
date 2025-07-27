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
- `level_up_costs.csv`: Universal level upgrade costs
- `star_upgrade_costs.csv`: Universal star upgrade costs
- `draw_cost.csv`: Gacha system costs
- And more...

**Data Loading**: CSV files are processed by generator scripts that destroy/recreate database records.

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

## Recent Updates
- [2025-07-23] [Equipment API Implementation]: Created dedicated `equip` API for empty slots and enhanced `replace` API with proper error handling and complete state responses. Fixed Sidekick equipment association. Both Hero and Sidekick equipment operations now work correctly with full data consistency.
```

### Example Update
```markdown
## Recent Updates  
- [2025-07-23] [Initial Analysis]: Created comprehensive project overview and documented core game systems, API patterns, and development workflows.
```

---

*This document serves as the primary knowledge base for Claude agents working on this project. Keep it current and comprehensive to ensure efficient development workflows.*