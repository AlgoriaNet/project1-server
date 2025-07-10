# Fix sidekick upgrades by creating specific upgrade effects for each sidekick
# Uses a different approach - store sidekick-specific data in the effects

puts "=== FIXING SIDEKICK UPGRADE DATA V2 ==="

# Clear existing upgrade effects  
puts "Clearing existing upgrade effects..."
BaseSkillLevelUpEffect.destroy_all

# Get all sidekicks
base_sidekicks = BaseSidekick.all.order(:id)
puts "Found #{base_sidekicks.count} base sidekicks"

# Define the upgrade levels
upgrade_levels = [2, 6, 8, 15, 20]

# Define unique descriptions for each sidekick
descriptions_by_sidekick = {
  "01_Zorath" => {
    2 => "Shadow Strike +1 (Max 3 active)",
    6 => "Shadow duration +2s; stealth +30%", 
    8 => "Shadow range +50%; damage +30%",
    15 => "Enemies in shadows take +30% damage for 3s",
    20 => "Shadow splits into 4 mini shadows at end"
  },
  "02_Gideon" => {
    2 => "Thunder damage +20%",
    6 => "Thunder multi-strike: 2 bolts",
    8 => "Thunder triple strike capability", 
    15 => "Thunder ultimate: devastating storm",
    20 => "Thunder legendary form: all stats +100%"
  },
  "03_Sylas" => {
    2 => "Blade cooldown -1s",
    6 => "Blade life steal +5%",
    8 => "Blade crit damage +40%",
    15 => "Blade regeneration +20 HP/s", 
    20 => "Blade resurrection: revive once per battle"
  },
  "04_Aurelia" => {
    2 => "Light range +30%",
    6 => "Light explosion on impact",
    8 => "Light bounce between enemies",
    15 => "Light time slow on activation",
    20 => "Light void portal: teleports enemies"
  },
  "05_Lyanna" => {
    2 => "Frost projectile speed +25%",
    6 => "Frost stun chance +15%", 
    8 => "Frost freeze effect on hit",
    15 => "Frost damage reflects to nearby enemies",
    20 => "Frost master strike: ignores all defenses"
  }
}

# Create default descriptions for remaining sidekicks
default_descriptions = {
  2 => "Attack damage +20%",
  6 => "Multi-shot: fires 2 projectiles", 
  8 => "Triple shot capability",
  15 => "Ultimate ability: devastating blast",
  20 => "Legendary form: all stats +100%"
}

# Create upgrade effects for each sidekick
base_sidekicks.each do |sidekick|
  puts "Creating upgrade effects for #{sidekick.name} (#{sidekick.fragment_name})"
  
  # Get descriptions for this sidekick or use defaults
  sidekick_descs = descriptions_by_sidekick[sidekick.fragment_name] || default_descriptions
  
  upgrade_levels.each do |level|
    description = sidekick_descs[level] || "#{sidekick.name} Level #{level} upgrade"
    
    # Create upgrade effect with sidekick info in the effects JSON
    BaseSkillLevelUpEffect.create!(
      skill_id: sidekick.skill_id,  # Keep using skill_id 1
      level: level,
      description: description,
      weight: 0,
      gold_cost: nil,
      effect_name: "Level #{level} Upgrade",
      effects: {
        level: level,
        upgrade_type: "skill_enhancement",
        sidekick_id: sidekick.id,           # Store sidekick ID here
        sidekick_fragment_name: sidekick.fragment_name  # Store fragment name here
      }.to_json
    )
    
    puts "  Created level #{level}: #{description}"
  end
end

# Summary
total_effects = BaseSkillLevelUpEffect.count
puts "\n=== SUMMARY ==="
puts "Total upgrade effects created: #{total_effects}"
puts "Sidekicks with upgrades: #{BaseSidekick.count}"
puts "Expected total: #{BaseSidekick.count * upgrade_levels.count}"
puts "Upgrade levels: #{upgrade_levels.join(', ')}"

puts "\n=== FIX COMPLETE - API Controller needs to be updated to filter by sidekick ==="