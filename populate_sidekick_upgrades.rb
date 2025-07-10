# Populate comprehensive sidekick upgrade data
# This script creates upgrade effects for all sidekicks with realistic dummy data

# Clear existing data
puts "Clearing existing upgrade effects..."
BaseSkillLevelUpEffect.destroy_all

# Define upgrade templates with realistic progression
upgrade_templates = [
  {
    level: 2,
    skill_book_cost: 50,
    gold_cost: 200,
    descriptions: [
      "Skill +1 (Max 3 active)",
      "Attack damage +20%",
      "Cooldown -1s",
      "Range +30%",
      "Projectile speed +25%"
    ]
  },
  {
    level: 4,
    skill_book_cost: 75,
    gold_cost: 350,
    descriptions: [
      "Skill pierces through enemies",
      "Attack speed +15%",
      "Crit chance +10%",
      "Area damage +25%",
      "Movement speed +20%"
    ]
  },
  {
    level: 6,
    skill_book_cost: 100,
    gold_cost: 500,
    descriptions: [
      "Skill duration +2s; damage -30%",
      "Multi-shot: fires 2 projectiles",
      "Life steal +5%",
      "Explosion on impact",
      "Stun chance +15%"
    ]
  },
  {
    level: 8,
    skill_book_cost: 150,
    gold_cost: 800,
    descriptions: [
      "Skill range +50%; damage +30%",
      "Triple shot capability",
      "Crit damage +40%",
      "Bounce between enemies",
      "Freeze effect on hit"
    ]
  },
  {
    level: 10,
    skill_book_cost: 200,
    gold_cost: 1200,
    descriptions: [
      "Skill homes in on enemies",
      "Chain lightning effect",
      "Damage over time +5s",
      "Armor penetration +25%",
      "Knockback force +50%"
    ]
  },
  {
    level: 12,
    skill_book_cost: 250,
    gold_cost: 1600,
    descriptions: [
      "Skill splits on impact",
      "Berserker mode: +50% damage when low HP",
      "Shield generation on crit",
      "Poison cloud on death",
      "Teleport to target"
    ]
  },
  {
    level: 15,
    skill_book_cost: 300,
    gold_cost: 2000,
    descriptions: [
      "Enemies hit take 30% more damage for 3s",
      "Ultimate ability: devastating blast",
      "Regeneration +20 HP/s",
      "Time slow on activation",
      "Damage reflects to nearby enemies"
    ]
  },
  {
    level: 18,
    skill_book_cost: 400,
    gold_cost: 2600,
    descriptions: [
      "Skill creates lingering damage zones",
      "Phantom strikes: attacks ignore armor",
      "Healing aura for allies",
      "Magnetic pull on enemies",
      "Energy drain from targets"
    ]
  },
  {
    level: 20,
    skill_book_cost: 500,
    gold_cost: 3000,
    descriptions: [
      "Skill splits into 4 mini versions at end",
      "Legendary form: all stats +100%",
      "Resurrection: revive once per battle",
      "Void portal: teleports enemies",
      "Master strike: ignores all defenses"
    ]
  },
  {
    level: 25,
    skill_book_cost: 750,
    gold_cost: 4000,
    descriptions: [
      "Transcendent power: reality-bending abilities",
      "Omnislash: hits all enemies simultaneously",
      "Time manipulation: rewind damage",
      "Elemental mastery: all damage types",
      "Godlike presence: intimidates all foes"
    ]
  }
]

# Get all sidekicks and their associated skills
base_sidekicks = BaseSidekick.all
puts "Found #{base_sidekicks.count} base sidekicks"

# Create upgrade effects for each sidekick
base_sidekicks.each_with_index do |sidekick, sidekick_index|
  puts "Processing #{sidekick.name} (#{sidekick.cn_name}) - Skill ID: #{sidekick.skill_id}"
  
  upgrade_templates.each_with_index do |template, template_index|
    # Select description based on sidekick type and level
    description = template[:descriptions][sidekick_index % template[:descriptions].length]
    
    # Create the upgrade effect
    effect = BaseSkillLevelUpEffect.create!(
      skill_id: sidekick.skill_id,
      level: template[:level],
      description: description,
      weight: template[:skill_book_cost],
      gold_cost: template[:gold_cost],
      effect_name: "Level #{template[:level]} Upgrade",
      effects: {
        damage_boost: (template[:level] * 0.1).round(2),
        cooldown_reduction: (template[:level] * 0.05).round(2),
        range_increase: (template[:level] * 0.03).round(2)
      }.to_json
    )
    
    puts "  Created level #{template[:level]} upgrade: #{description}"
  end
end

# Summary
total_effects = BaseSkillLevelUpEffect.count
puts "\n=== SUMMARY ==="
puts "Total upgrade effects created: #{total_effects}"
puts "Sidekicks with upgrades: #{BaseSidekick.count}"
puts "Upgrade levels per sidekick: #{upgrade_templates.count}"
puts "Gold cost range: #{upgrade_templates.first[:gold_cost]} - #{upgrade_templates.last[:gold_cost]}"
puts "Skill book cost range: #{upgrade_templates.first[:skill_book_cost]} - #{upgrade_templates.last[:skill_book_cost]}"

# Verify data integrity
puts "\n=== VERIFICATION ==="
BaseSkillLevelUpEffect.joins(:base_skill).includes(:base_skill).group('base_skills.name').count.each do |skill_name, count|
  puts "#{skill_name}: #{count} upgrade levels"
end