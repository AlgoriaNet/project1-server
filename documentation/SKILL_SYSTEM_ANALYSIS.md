# Skill System Analysis & Design Document

## 🎯 Core Understanding

### System Overview
- **21 Characters Total**: 1 Hero (base_id: 0) + 20 Sidekicks (base_id: 1-20)
- **Each Character = 1 Unique Skill** with multiple upgrade attributes
- **Battle Level-Up Flow**: Player levels up → UI shows 3 skill upgrade options → Player selects 1
- **Frontend Handles**: All selection logic, effect application, no backend persistence needed
- **Backend Provides**: Complete pool of possible skill upgrade effects

## 📊 Hero Skill Analysis (From Image #1)

### Hero Skill: Gun Shooting (枪击)
**Categories & Effects Available:**

#### 常规伤害 (Normal Damage)
- 伤害 (Damage) → 伤害+N
- 穿透 (Penetration) → 穿透+N  
- 技能范围 (Skill Range) → 持续时间+N
- 持续时间 (Duration) → 技能CD-N
- CD (Cooldown) → 伤害次数+N
- 伤害次数 (Damage Count) → 伤害加深+N%
- Additional effects: 伤害范围增加N格, 出现二次伤害, 出现冰冻效果, 出现减速效果, 出现燃烧效果, 出现爆炸效果, 出现击退效果

## 🔥 Sidekick Skills Analysis (From Detailed Charts)

*Note: The following analysis is based on initial design documents. For the most current and accurate skill parameters, always refer to the `lib/config/base_skills.csv` file, but be aware that some data may be for placeholder skills and is subject to change.*

### Fire Skills (火系)
1. **烈焰射线 (Flame Ray)** - Current DB: "Skill_FireTornado" 
   - Damage: 0.5, Duration: 3.0, CD: 8.0, Type: Fire
   
2. **火球术 (Fireball)** - Current DB: "Skill_Blazing_Ray"
   - Damage: 1.2, Duration: 1.5, CD: 4.5, Type: Fire
   
3. **火球术 (Area Fire)** - Current DB: "Skill_Inferno"
   - Damage: 0.8, Duration: 1.5, CD: 6.0, Type: Fire

### Ice Skills (冰系)
4. **冰锥术 (Ice Spike)** - Current DB: "Skill_IceCrackBullet"
   - Damage: 1.2, Duration: 1.0, CD: 5.0, Type: Ice
   
5. **冰霜屏障 (Frost Barrier)** - Current DB: "Skill_Ice_Spike"
   - Damage: 0.2, Duration: 2.5, CD: 10.0, Scope: 3.5, Type: Ice
   
6. **寒霜绽放 (Frost Bloom)** - Current DB: "Skill_Ice_Spear"
   - Damage: 0.8, Duration: 2.0, CD: 6.0, Scope: 2.0, Type: Ice

### Wind Skills (风系)  
7. **风暴之刃 (Storm Blade)** - Current DB: "Skill_Storm_Blade" ✅ MATCH
   - Damage: 0.5, Duration: 1.5, CD: 12.0, Type: Wind
   
8. **龙卷风 (Tornado)** - Current DB: Match unclear
   - Damage: 1.0, Duration: 1.0, CD: 6.0, Scope: 1.5, Type: Wind
   
9. **风之羽 (Wind Feather)** - Current DB: "Skill_Wind_Feather" ✅ MATCH
   - Damage: 1.2, Duration: 1.0, CD: 5.0, Type: Wind

### Light Skills (光系)
10. **雷击 (Thunder)** - Current DB: "Skill_Chain_Lightning" ✅ MATCH
    - Damage: 1.2, Duration: 1.0, CD: 6.0, Type: Light
    
11. **寂灭之光 (Annihilation Light)** - Current DB: "Skill_Thunder_Bolt"
    - Damage: 0.5, Duration: 2.0, CD: 8.0, Scope: 1.5, Type: Light
    
12. **神圣护佑 (Divine Protection)** - Current DB: "Skill_Mega_Laser"
    - Special healing skill, CD: 30s

### Dark Skills (暗系)
13. **黑暗之触 (Dark Touch)** - Current DB: "Skill_Dark_Touch" ✅ MATCH  
    - Damage: 0.5, Duration: 2.0, CD: 6.0, Type: Dark
    
14. **亡灵召唤 (Soul Summon)** - Current DB: Match unclear
    - Damage: 0.8, Duration: 3.0, CD: 6.0, Type: Dark

### Physical Skills (物理系)
15. **飞箭投掷 (Arrow Throw)** - Current DB: "Skill_Bomb_Blast"
    - Damage: 1.0, Duration: 1.5, CD: 4.0, Type: Physical
    
16. **空中扫射 (Aerial Strafe)** - Current DB: Match unclear  
    - Damage: 0.6, Duration: 2.0, CD: 10.0, Scope: 1.5, Type: Physical

## 🗄️ Current Database Mapping

*Note: The skill names in the following table are taken directly from `base_skills.csv`. There is a known discrepancy where the CSV contains multiple specific placeholder names (e.g., `Skill_Dummy_Gideon`, `Skill_Dummy_Nyx`), while other parts of the project may only reference a single generic `Skill_Dummy`. This table reflects the CSV's current state.*

*Sidekick to Skill mapping is 1-to-1 as defined in `base_sidekicks.csv`. The following table reflects the skill data from `base_skills.csv`.*

### ✅ Existing Skills (as of 2025-08-27)
| Skill ID | Name | Type | CD | Damage | Status |
|---|---|---|---|---|---|
| 1 | Skill_FireTornado | Fire | 8.0 | 0.5 | Implemented |
| 2 | Skill_Dummy_Gideon | Physical | 5.0 | 1.0 | Placeholder |
| 3 | Skill_Wind_Feather | Wind | 5.0 | 1.2 | Implemented |
| 4 | Skill_Storm_Blade | Wind | 12.0 | 0.5 | Implemented |
| 5 | Skill_Black_Hole | Dark | 10.0 | 0.5 | Implemented |
| 6 | Skill_Dark_Touch | Dark | 6.0 | 0.8 | Implemented |
| 7 | Skill_Chain_Lightning | Light | 6.0 | 1.2 | Implemented |
| 8 | Skill_Dummy_Rowan | Physical | 5.0 | 1.0 | Placeholder |
| 9 | Skill_IceCrackBullet | Ice | 5.0 | 1.2 | Implemented |
| 10 | Skill_Inferno | Fire | 6.0 | 0.8 | Implemented |
| 11 | Skill_Thunder_Bolt | Light | 8.0 | 0.5 | Implemented |
| 12 | Skill_Ice_Spike | Ice | 10.0 | 0.2 | Implemented |
| 13 | Skill_Blazing_Ray | Fire | 4.5 | 1.2 | Implemented |
| 14 | Skill_Mega_Laser | Light | 30.0 | 0.0 | Implemented |
| 15 | Skill_Dummy_Velan | Physical | 5.0 | 1.0 | Placeholder |
| 16 | Skill_Dummy_Ragnar | Physical | 5.0 | 1.0 | Placeholder |
| 17 | Skill_Bomb_Blast | Physical | 4.0 | 1.0 | Implemented |
| 18 | Skill_Dummy_Ugra | Physical | 5.0 | 1.0 | Placeholder |
| 19 | Skill_Ice_Spear | Ice | 6.0 | 0.8 | Implemented |
| 20 | Skill_Dummy_Nyx | Physical | 5.0 | 1.0 | Placeholder |

### ❌ Missing Skills Needed
- **Hero Gun Shooting** (base_id: 0) - Must create
- **龙卷风 (Tornado)** - Wind skill from charts  
- **空中扫射 (Aerial Strafe)** - Physical skill from charts
- **亡灵召唤 (Soul Summon)** - Dark skill from charts

## 📋 Upgrade System Design

### Level-Based Upgrades (From Charts)
Each skill has upgrades at specific levels:
- **Lv.2**: Basic damage/effect boost
- **Lv.6-8**: Additional mechanics 
- **Lv.10-15**: Advanced effects
- **Lv.20**: Ultimate upgrades

### Upgrade Categories
1. **Damage Boost** (+N damage or +N%)
2. **Cooldown Reduction** (-N seconds)
3. **Range/Scope Increase** (+N units)
4. **Duration Extension** (+N seconds)
5. **Count Increase** (+N instances)
6. **Special Effects** (burning, freezing, knockback, etc.)

## 🎲 Selection Logic Requirements

### 3-Option Generation Rules
1. **Character Priority**: First try different characters' skills
2. **Attribute Fallback**: If not enough characters, use different attributes of same skill
3. **No Duplicates**: Within same selection round only
4. **Weight-Based**: Use Weight field for probability
5. **Max Count**: Respect MaxCount limits

### Example Scenarios
- **Hero + 3 Sidekicks**: 3 different character skills
- **Hero Only**: 3 different hero skill attributes  
- **Hero + 1 Sidekick**: 2 character skills + 1 attribute variation

## ⚠️ Critical Implementation Notes

1. **Character-Centric Design**: Use character base_id as primary key, not skill_id
2. **Hero Integration**: Add Hero (base_id: 0) with gun skill and attributes
3. **Skill Matching**: Map existing skills to new effect system where possible
4. **Frontend Compatibility**: Must match exact JSON structure expected
5. **No Backend State**: Effects are battle-session only, no persistence

## 🔄 Next Steps

1. **Verify Current Database**: Check which skills already exist vs. needed
2. **Create Hero Skill Data**: Define gun shooting skill and attributes  
3. **Map Existing Skills**: Connect current sidekick skills to upgrade effects
4. **Generate Missing Skills**: Create data for unmapped skills from charts
5. **Build Effect System**: Implement character-centric BaseSkillLevelUpEffect replacement
6. **Test Integration**: Verify frontend receives expected data structure

---

*This analysis will guide the implementation to ensure we build the right system that matches both the design vision and current codebase reality.*

## 🔄 Revision History

**2025-08-27 (Gemini):**
- Updated skill data table to align with `base_skills.csv`.
- Corrected sidekick/skill mapping status and noted placeholder skills.
- Added disclaimer that CSVs are the source of truth for current skill data.
