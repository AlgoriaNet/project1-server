# Gemstone System Documentation

## Overview
The gemstone system allows players to enhance equipment by embedding gems that provide combat stat bonuses. Gemstones are categorized by equipment slot and have 7 quality tiers (levels 1-7) represented by different colors.

## Gemstone Tiers and Properties

### Tier System
| Color | ID | Level | Properties | Attribute Range |
|-------|----|---------|-----------|-----------------| 
| 白色 (White) | Gem_01 | 1级 | Single Property | 1~11 |
| 绿色 (Green) | Gem_02 | 2级 | Single Property | 1~11 |
| 蓝色 (Blue) | Gem_03 | 3级 | Single Property | 1~11 |
| 紫色 (Purple) | Gem_04 | 4级 | Single Property | 1~11 |
| 黄色 (Yellow) | Gem_05 | 5级 | Dual Properties | 1~22 |
| 粉色 (Pink) | Gem_06 | 6级 | Dual Properties | 1~22 |
| 红色 (Red) | Gem_07 | 7级 | Dual Properties | 1~22 |

### Property Generation Rules
- **Levels 1-4**: Generate 1 attribute randomly from basic attributes (1-11)
- **Levels 5-7**: Generate 2 attributes randomly from all attributes (1-22), no duplicates
- **Red gems (Level 7)**: Can be rerolled to change attributes

## Gemstone Attributes

### Basic Attributes (1-11)
| ID | Attribute | Growth Factor |
|----|-----------|---------------|
| 1 | 防线血量提升 (Defense HP Boost) | 0.3 |
| 2 | 攻击 (Attack) | 0.24 |
| 3 | 暴击率 (Critical Rate) | 0.12 |
| 4 | 暴击伤害 (Critical Damage) | 0.24 |
| 5 | 枪械伤害 (Gun Damage) | 0.24 |
| 6 | 火系伤害 (Fire Damage) | 0.24 |
| 7 | 冰系伤害 (Ice Damage) | 0.24 |
| 8 | 风系伤害 (Wind Damage) | 0.24 |
| 9 | 光系伤害 (Light Damage) | 0.24 |
| 10 | 暗系伤害 (Dark Damage) | 0.24 |
| 11 | 物理系伤害 (Physical Damage) | 0.24 |

### Advanced Attributes (12-22)
| ID | Attribute | Growth Factor |
|----|-----------|---------------|
| 12 | 杀死精英怪回复防线血量 (Elite Kill HP Recovery) | 0.18 |
| 13 | 杀死一只怪后回复防线血量 (Monster Kill HP Recovery) | 0.18 |
| 14 | 杀敌回血 (Kill Recovery) | 0.18 |
| 15 | 杀敌回蓝 (Kill Mana Recovery) | 0.18 |
| 16 | 受到暴击概率下降 (Critical Hit Resistance) | 0.12 |
| 17 | 受到伤害减少 (Damage Reduction) | 0.18 |
| 18 | 受到控制时间减少 (CC Duration Reduction) | 0.18 |
| 19 | 闪避率 (Dodge Rate) | 0.12 |
| 20 | 护盾值提升 (Shield Boost) | 0.3 |
| 21 | 技能冷却时间缩短 (Skill Cooldown Reduction) | 0.12 |
| 22 | 技能蓝耗降低 (Skill Mana Cost Reduction) | 0.12 |

## Attribute Value Calculation

### Formula
- **Single Property Gems (Levels 1-4)**: 
  ```
  Attribute Value = Base Value × Growth Factor × (Level²)
  ```

- **Dual Property Gems (Levels 5-7)**:
  ```
  Each Attribute Value = Base Value × Growth Factor × (Level²) × 0.75
  ```

### Parameters
- **Base Value**: 100 (default)
- **Growth Factor**: See attribute tables above
- **Level**: Gemstone tier (1-7)

### Examples
- Level 2 Green Gem with Attack attribute:
  - Value = 100 × 0.24 × (2²) = 100 × 0.24 × 4 = 96

- Level 5 Yellow Gem with Attack + Critical Rate:
  - Attack Value = 100 × 0.24 × (5²) × 0.75 = 100 × 0.24 × 25 × 0.75 = 450
  - Critical Rate Value = 100 × 0.12 × (5²) × 0.75 = 100 × 0.12 × 25 × 0.75 = 225

## Gemstone Acquisition and Synthesis

### Acquisition Methods
- **Gacha Draws**: Random gemstone rewards from draw pools
- **Main Stage Drops**: Gemstones obtained through story progression
- **Dungeon Drops**: Gemstones from completing dungeons
- **Synthesis**: Combine lower-tier gems to create higher-tier ones

### Synthesis Rules
- **Requirement**: 5 gemstones of the same equipment slot and same tier
- **Result**: 1 gemstone of the same equipment slot, one tier higher
- **Attribute Generation**: New gemstone gets randomly generated attributes based on its tier rules

#### Examples
- 5× Level 1 (White) Chest gems → 1× Level 2 (Green) Chest gem (1 random basic attribute)
- 5× Level 4 (Purple) Helmet gems → 1× Level 5 (Yellow) Helmet gem (2 random attributes from full pool)

## Equipment Integration
- Gemstones are embedded into equipment based on **equipment slot** compatibility
- Each equipment piece has gemstone slots that accept gems of the corresponding equipment part
- Gemstones provide passive stat bonuses when equipped
- Higher-tier gemstones provide significantly more powerful bonuses

## Technical Implementation Notes
- Gemstone data is stored in the `Gemstone` model
- Equipment integration handled through the `Equipment` model's gemstone associations
- Attribute values calculated dynamically based on the formulas above
- WebSocket APIs available for gemstone management operations

---

*Last Updated: 2025-08-01*
*Based on: Game design specifications and system analysis*