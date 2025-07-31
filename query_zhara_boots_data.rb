#!/usr/bin/env ruby
require_relative 'config/environment'

puts '=== Zhara Boots Equipment and Gems Query ==='
puts ''

# First, let's find all players who have Zhara
zhara_base = BaseSidekick.find_by(fragment_name: "06_Zhara")
if zhara_base.nil?
  puts "ERROR: Could not find BaseSidekick with fragment_name '06_Zhara'"
  exit 1
end

puts "Found Zhara BaseSidekick: ID=#{zhara_base.id}, Name=#{zhara_base.name}"
puts ''

# Find all Zhara sidekicks owned by players
zhara_sidekicks = Sidekick.where(base_id: zhara_base.id)
puts "Found #{zhara_sidekicks.count} Zhara sidekicks owned by players:"

zhara_sidekicks.each do |sidekick|
  player = Player.find(sidekick.player_id)
  puts "  - Player #{player.id} (#{player.name}): Zhara ID=#{sidekick.id}, Star=#{sidekick.star}, Level=#{sidekick.skill_level}"
end
puts ''

# For each player with Zhara, check boots equipment
zhara_sidekicks.each do |sidekick|
  player = Player.find(sidekick.player_id)
  puts "=== PLAYER #{player.id} (#{player.name}) - ZHARA BOOTS ANALYSIS ==="
  
  # Get all equipment for this Zhara sidekick
  zhara_equipment = Equipment.where(equip_with_sidekick_id: sidekick.id)
  puts "Total equipment on Zhara: #{zhara_equipment.count}"
  
  # Filter for boots equipment
  boots_equipment = zhara_equipment.joins(:base_equipment).where(base_equipments: { part: 'Boots' })
  puts "Boots equipment on Zhara: #{boots_equipment.count}"
  
  if boots_equipment.any?
    boots_equipment.each do |equipment|
      puts "  📦 BOOTS EQUIPMENT:"
      puts "    - Equipment ID: #{equipment.id}"
      puts "    - Base Equipment: #{equipment.base_equipment.name} (ID: #{equipment.base_equipment_id})"
      puts "    - Quality: #{equipment.base_equipment.quality}"
      puts "    - Intensify Level: #{equipment.intensify_level}"
      puts "    - Nearby Attributes: #{equipment.nearby_attributes}"
      puts ""
      
      # Get embedded gems in this boots equipment
      embedded_gems = Gemstone.where(equipment_id: equipment.id)
      puts "    💎 EMBEDDED GEMS (#{embedded_gems.count}):"
      
      if embedded_gems.any?
        embedded_gems.each do |gem|
          entry = gem.gemstone_entry
          puts "      - Slot #{gem.slot_number}: #{entry.effect_name} Lv.#{gem.level}"
          puts "        Effect: #{gem.dynamic_effect_description}"
          puts "        Value: #{entry["level_#{gem.level}_value"]}"
          puts ""
        end
      else
        puts "      (No gems embedded)"
      end
      puts ""
    end
  else
    puts "  ❌ No boots equipment found on Zhara"
  end
  
  # Get all boots gems available in this player's inventory
  available_boots_gems = Gemstone.where(
    player_id: player.id,
    part: 'Boots',
    is_in_inventory: true
  ).order(:level, :entry_id)
  
  puts "  💼 AVAILABLE BOOTS GEMS IN INVENTORY (#{available_boots_gems.count}):"
  if available_boots_gems.any?
    available_boots_gems.each do |gem|
      entry = gem.gemstone_entry
      puts "    - #{entry.effect_name} Lv.#{gem.level} (#{gem.level_name})"
      puts "      Effect: #{gem.dynamic_effect_description}"
      puts "      Value: #{entry["level_#{gem.level}_value"]}"
      puts "      Locked: #{gem.is_locked ? 'Yes' : 'No'}"
      puts ""
    end
  else
    puts "    (No boots gems in inventory)"
  end
  
  puts "=" * 60
  puts ""
end

puts 'Query complete!'