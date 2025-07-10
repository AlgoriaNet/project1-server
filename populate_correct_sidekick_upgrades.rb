# Populate sidekick upgrade data with correct levels (2, 6, 8, 15, 20)
# Remove costs as requested

# Clear existing data
puts "Clearing existing upgrade effects..."
BaseSkillLevelUpEffect.destroy_all

# Define the correct upgrade levels
upgrade_levels = [2, 6, 8, 15, 20]

# Define upgrade descriptions for each level
level_descriptions = {
  2 => [
    "Skill +1 (Max 3 active)",
    "Attack damage +20%", 
    "Cooldown reduction -1s",
    "Range increase +30%",
    "Projectile speed +25%"
  ],
  6 => [
    "Skill duration +2s; damage -30%",
    "Multi-shot: fires 2 projectiles",
    "Life steal +5%", 
    "Explosion on impact",
    "Stun chance +15%"
  ],
  8 => [
    "Skill range +50%; damage +30%",
    "Triple shot capability",
    "Crit damage +40%",
    "Bounce between enemies", 
    "Freeze effect on hit"
  ],
  15 => [
    "Enemies hit take 30% more damage for 3s",
    "Ultimate ability: devastating blast",
    "Regeneration +20 HP/s",
    "Time slow on activation",
    "Damage reflects to nearby enemies"
  ],
  20 => [
    "Skill splits into 4 mini versions at end",
    "Legendary form: all stats +100%",
    "Resurrection: revive once per battle", 
    "Void portal: teleports enemies",
    "Master strike: ignores all defenses"
  ]
}

# Get all sidekicks
base_sidekicks = BaseSidekick.all
puts "Found #{base_sidekicks.count} base sidekicks"

# Create upgrade effects for each sidekick
base_sidekicks.each_with_index do |sidekick, sidekick_index|
  puts "Processing #{sidekick.name} (#{sidekick.cn_name}) - Skill ID: #{sidekick.skill_id}"
  
  upgrade_levels.each do |level|
    # Select description based on sidekick type and level
    descriptions = level_descriptions[level]
    description = descriptions[sidekick_index % descriptions.length]
    
    # Create the upgrade effect without costs
    effect = BaseSkillLevelUpEffect.create!(
      skill_id: sidekick.skill_id,
      level: level,
      description: description,
      weight: 0,  # Remove skill book cost
      gold_cost: nil,  # Remove gold cost
      effect_name: "Level #{level} Upgrade",
      effects: {
        level: level,
        upgrade_type: "skill_enhancement"
      }.to_json
    )
    
    puts "  Created level #{level} upgrade: #{description}"
  end
end

# Summary
total_effects = BaseSkillLevelUpEffect.count
puts "\n=== SUMMARY ==="
puts "Total upgrade effects created: #{total_effects}"
puts "Sidekicks with upgrades: #{BaseSidekick.count}"
puts "Upgrade levels: #{upgrade_levels.join(', ')}"
puts "Costs removed as requested"

# Verify data integrity
puts "\n=== VERIFICATION ==="
BaseSkillLevelUpEffect.joins(:base_skill).includes(:base_skill).group('base_skills.name').count.each do |skill_name, count|
  puts "#{skill_name}: #{count} upgrade levels"
end