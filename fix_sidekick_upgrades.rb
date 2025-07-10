# Fix the sidekick upgrade data - create unique skill IDs and proper upgrade effects
# This fixes the bug where all sidekicks shared skill_id=1 causing duplicate results

puts "=== FIXING SIDEKICK UPGRADE DATA ==="

# Clear existing upgrade effects
puts "Clearing existing upgrade effects..."
BaseSkillLevelUpEffect.destroy_all

# Get all sidekicks and assign them unique skill IDs
base_sidekicks = BaseSidekick.all.order(:id)
puts "Found #{base_sidekicks.count} base sidekicks"

# Update each sidekick to have a unique skill_id
base_sidekicks.each_with_index do |sidekick, index|
  unique_skill_id = sidekick.id  # Use the sidekick's own ID as the skill_id
  
  # Update the sidekick's skill_id to be unique
  sidekick.update!(skill_id: unique_skill_id)
  puts "Updated #{sidekick.name} to use skill_id: #{unique_skill_id}"
end

# Define the upgrade levels (as originally specified)
upgrade_levels = [2, 6, 8, 15, 20]

# Define unique descriptions for each sidekick
sidekick_descriptions = {
  2 => {
    "Zorath" => "Shadow Strike +1 (Max 3 active)",
    "Gideon" => "Thunder damage +20%", 
    "Sylas" => "Blade cooldown -1s",
    "Aurelia" => "Light range +30%",
    "Lyanna" => "Frost projectile speed +25%",
    "Zhara" => "Fire skill +1 (Max 3 active)",
    "Elenya" => "Wind attack damage +20%",
    "Rowan" => "Earth cooldown -1s", 
    "Liraen" => "Nature range +30%",
    "Cedric" => "Steel projectile speed +25%",
    "Selena" => "Moon skill +1 (Max 3 active)",
    "Morgath" => "Dark attack damage +20%",
    "Zyphira" => "Storm cooldown -1s",
    "Kaelith" => "Crystal range +30%",
    "Velan" => "Void projectile speed +25%",
    "Ragnar" => "Blood skill +1 (Max 3 active)",
    "Lucien" => "Light attack damage +20%",
    "Ugra" => "Beast cooldown -1s",
    "Eleanor" => "Royal range +30%", 
    "Nyx" => "Shadow projectile speed +25%"
  },
  6 => {
    "Zorath" => "Shadow duration +2s; stealth +30%",
    "Gideon" => "Thunder multi-strike: 2 bolts",
    "Sylas" => "Blade life steal +5%",
    "Aurelia" => "Light explosion on impact", 
    "Lyanna" => "Frost stun chance +15%",
    "Zhara" => "Fire duration +2s; burn damage",
    "Elenya" => "Wind multi-shot: 2 projectiles",
    "Rowan" => "Earth life steal +5%",
    "Liraen" => "Nature explosion on impact",
    "Cedric" => "Steel stun chance +15%",
    "Selena" => "Moon duration +2s; charm effect",
    "Morgath" => "Dark multi-shot: 2 projectiles", 
    "Zyphira" => "Storm life steal +5%",
    "Kaelith" => "Crystal explosion on impact",
    "Velan" => "Void stun chance +15%",
    "Ragnar" => "Blood duration +2s; drain life",
    "Lucien" => "Light multi-shot: 2 projectiles",
    "Ugra" => "Beast life steal +5%",
    "Eleanor" => "Royal explosion on impact",
    "Nyx" => "Shadow stun chance +15%"
  },
  8 => {
    "Zorath" => "Shadow range +50%; damage +30%",
    "Gideon" => "Thunder triple strike capability",
    "Sylas" => "Blade crit damage +40%",
    "Aurelia" => "Light bounce between enemies",
    "Lyanna" => "Frost freeze effect on hit",
    "Zhara" => "Fire range +50%; damage +30%",
    "Elenya" => "Wind triple shot capability", 
    "Rowan" => "Earth crit damage +40%",
    "Liraen" => "Nature bounce between enemies",
    "Cedric" => "Steel freeze effect on hit",
    "Selena" => "Moon range +50%; damage +30%",
    "Morgath" => "Dark triple shot capability",
    "Zyphira" => "Storm crit damage +40%",
    "Kaelith" => "Crystal bounce between enemies", 
    "Velan" => "Void freeze effect on hit",
    "Ragnar" => "Blood range +50%; damage +30%",
    "Lucien" => "Light triple shot capability",
    "Ugra" => "Beast crit damage +40%",
    "Eleanor" => "Royal bounce between enemies",
    "Nyx" => "Shadow freeze effect on hit"
  },
  15 => {
    "Zorath" => "Enemies in shadows take +30% damage for 3s",
    "Gideon" => "Thunder ultimate: devastating storm",
    "Sylas" => "Blade regeneration +20 HP/s",
    "Aurelia" => "Light time slow on activation",
    "Lyanna" => "Frost damage reflects to nearby enemies",
    "Zhara" => "Fire enemies take +30% damage for 3s",
    "Elenya" => "Wind ultimate: devastating tornado",
    "Rowan" => "Earth regeneration +20 HP/s",
    "Liraen" => "Nature time slow on activation", 
    "Cedric" => "Steel damage reflects to nearby enemies",
    "Selena" => "Moon enemies take +30% damage for 3s",
    "Morgath" => "Dark ultimate: devastating void",
    "Zyphira" => "Storm regeneration +20 HP/s",
    "Kaelith" => "Crystal time slow on activation",
    "Velan" => "Void damage reflects to nearby enemies",
    "Ragnar" => "Blood enemies take +30% damage for 3s",
    "Lucien" => "Light ultimate: devastating radiance", 
    "Ugra" => "Beast regeneration +20 HP/s",
    "Eleanor" => "Royal time slow on activation",
    "Nyx" => "Shadow damage reflects to nearby enemies"
  },
  20 => {
    "Zorath" => "Shadow splits into 4 mini shadows at end",
    "Gideon" => "Thunder legendary form: all stats +100%",
    "Sylas" => "Blade resurrection: revive once per battle",
    "Aurelia" => "Light void portal: teleports enemies",
    "Lyanna" => "Frost master strike: ignores all defenses",
    "Zhara" => "Fire splits into 4 mini flames at end",
    "Elenya" => "Wind legendary form: all stats +100%",
    "Rowan" => "Earth resurrection: revive once per battle",
    "Liraen" => "Nature void portal: teleports enemies",
    "Cedric" => "Steel master strike: ignores all defenses",
    "Selena" => "Moon splits into 4 mini moons at end",
    "Morgath" => "Dark legendary form: all stats +100%", 
    "Zyphira" => "Storm resurrection: revive once per battle",
    "Kaelith" => "Crystal void portal: teleports enemies",
    "Velan" => "Void master strike: ignores all defenses",
    "Ragnar" => "Blood splits into 4 mini bloods at end",
    "Lucien" => "Light legendary form: all stats +100%",
    "Ugra" => "Beast resurrection: revive once per battle",
    "Eleanor" => "Royal void portal: teleports enemies", 
    "Nyx" => "Shadow master strike: ignores all defenses"
  }
}

# Create upgrade effects for each sidekick with their unique skill_id
base_sidekicks.each do |sidekick|
  puts "Creating upgrade effects for #{sidekick.name} (skill_id: #{sidekick.skill_id})"
  
  upgrade_levels.each do |level|
    description = sidekick_descriptions[level][sidekick.name] || "#{sidekick.name} Level #{level} upgrade"
    
    BaseSkillLevelUpEffect.create!(
      skill_id: sidekick.skill_id,  # Now unique per sidekick
      level: level,
      description: description,
      weight: 0,
      gold_cost: nil,
      effect_name: "Level #{level} Upgrade",
      effects: {
        level: level,
        upgrade_type: "skill_enhancement"
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

# Verify each sidekick has exactly 5 upgrade levels
puts "\n=== VERIFICATION ==="
BaseSidekick.all.each do |sidekick|
  count = BaseSkillLevelUpEffect.where(skill_id: sidekick.skill_id).count
  puts "#{sidekick.name} (#{sidekick.fragment_name}): #{count} upgrade levels"
  if count != 5
    puts "  ERROR: Expected 5 levels, got #{count}!"
  end
end

puts "\n=== FIX COMPLETE ==="