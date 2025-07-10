# Sidekicks System Architecture Memo

## Overview
The sidekicks system is a core game mechanic that allows players to collect, upgrade, and deploy AI companions to assist in battles. The system consists of two main components: base templates and player-owned instances.

## Database Structure

### Core Tables

#### `base_sidekicks` (Templates)
- **Purpose**: Defines template data for all sidekick types
- **Key Fields**:
  - `id`: Primary key
  - `name`: English name (e.g., "Zorath", "Gideon")
  - `cn_name`: Chinese name (e.g., "佐拉斯", "吉迪恩")
  - `skill_id`: Links to base_skills table
  - `character`: Special traits/characteristics
  - `atk`, `def`, `cri`, `crt`: Base combat stats
  - `variety_damage`: JSON field for damage type multipliers
  - Display assets: `drawing_icon`, `fragment_name`, `card_name`, `portrait_icon`, `skill_icon`, `skill_book_icon`

#### `sidekicks` (Player Instances)
- **Purpose**: Player-owned sidekick instances
- **Key Fields**:
  - `base_id`: References base_sidekicks template
  - `player_id`: Owner reference
  - `skill_level`: Current upgrade level
  - `star`: Star rating/rarity
  - `is_deployed`: Battle formation status

#### `base_skill_level_up_effects` (Upgrade System)
- **Purpose**: Defines upgrade progression for sidekick skills
- **Key Fields**:
  - `skill_id`: Links to base_skills
  - `level`: Upgrade level (2, 6, 8, 15, 20, etc.)
  - `description`: Upgrade description text
  - `weight`: Skill book cost
  - `gold_cost`: Gold coin cost (recently added)
  - `effects`: JSON field for stat modifications

## System Interactions

### Player Integration
- Players can own multiple sidekicks via `Player.has_many :sidekicks`
- Each sidekick is unique to a player (no shared instances)
- Player's `summoned_allies` JSON field tracks collected sidekicks

### Battle System
- `BattleFormation` model manages team composition
- Supports up to 4 sidekicks per formation (sidekick1_id through sidekick4_id)
- Players can have multiple formations (up to 3 sets)
- Sidekicks can be equipped with gear via `Equipment` model

### Equipment System
- Sidekicks can equip items through `Equipment.belongs_to :sidekick`
- Equipment provides stat bonuses and additional abilities
- Gemstones can be inlaid into equipment for further customization

### Skill System
- Each sidekick has a base skill defined in `base_skills` table
- Skills have complex parameters: damage ratios, cooldowns, targeting, etc.
- Skill upgrades unlock at specific levels with costs in skill books and gold

## Data Flow

### Sidekick Creation
1. Base templates loaded from CSV (`lib/config/base_sidekicks.csv`)
2. `GenerateBaseSidekicks` class processes CSV into `base_sidekicks` table
3. Players acquire sidekicks through draw/gacha system
4. New `Sidekick` instance created with reference to base template

### Upgrade Process
1. Player selects sidekick for upgrade
2. System checks current `skill_level` and required resources
3. Deducts skill books and gold from player inventory
4. Increments `skill_level` and applies stat bonuses
5. Unlocks new abilities based on `base_skill_level_up_effects`

### Battle Deployment
1. Player configures `BattleFormation` with selected sidekicks
2. System validates formation (max 4 sidekicks)
3. Battle calculations use base stats + equipment bonuses + skill effects
4. Combat results influence experience and rewards

## API Endpoints

### `/api/allies/:ally_id/upgrade_levels` (AlliesController)
- **Purpose**: Retrieve upgrade information for a specific sidekick
- **Input**: `ally_id` (fragment_name, e.g., "02_Gideon")
- **Output**: Upgrade levels with descriptions, costs, and unlock status
- **Implementation**: Queries `BaseSkillLevelUpEffect` based on sidekick's skill_id

## Current Status & Issues

### Completed Features
- Base sidekick templates (20 unique sidekicks)
- Player sidekick instances and ownership
- Battle formation system
- Equipment and gemstone integration
- Basic upgrade level structure

### Incomplete/Pending Tasks
1. **Dummy Data Population**: Gold costs and skill book requirements need realistic values
2. **Upgrade Level Descriptions**: Many upgrade effects lack proper descriptions
3. **Balance Testing**: Combat stats and upgrade costs need balancing
4. **API Integration**: Frontend integration for upgrade system

### Recent Changes
- Added `gold_cost` field to upgrade effects (migration 20250709160640)
- Created `update_gold_costs.rb` script for populating gold costs
- Only skill_id=1 has sample gold costs (levels 2,6,8,15,20)

## Technical Notes

### Performance Considerations
- CSV loading destroys all existing data (`BaseSidekick.destroy_all`)
- Large JSON fields for variety_damage and effects may impact queries
- Consider indexing frequently queried fields (cn_name, fragment_name)

### Code Quality
- Models follow Rails conventions with proper associations
- Validation rules ensure data integrity
- WebSocket JSON serialization via `as_ws_json` methods
- Proper foreign key constraints in database

### Future Enhancements
1. Implement sidekick fusion/evolution system
2. Add AI behavior patterns for different sidekick types
3. Create sidekick-specific equipment restrictions
4. Implement rarity tiers and collection bonuses