#!/usr/bin/env ruby
require_relative 'config/environment'

puts '=== ZHARA BOOTS SUMMARY ==='
puts ''

# Find Zhara
zhara_base = BaseSidekick.find_by(fragment_name: "06_Zhara")
zhara_sidekick = Sidekick.find_by(base_id: zhara_base.id)
player = Player.find(zhara_sidekick.player_id)

puts "Player: #{player.name} (ID: #{player.id})"
puts "Zhara: Star #{zhara_sidekick.star}, Level #{zhara_sidekick.skill_level}"
puts ''

# Get boots equipment
boots_equipment = Equipment.joins(:base_equipment)
                           .where(equip_with_sidekick_id: zhara_sidekick.id, 
                                  base_equipments: { part: 'Boots' })
                           .first

if boots_equipment
  puts "🥾 ZHARA'S BOOTS: #{boots_equipment.base_equipment.name}"
  puts "   Quality: #{boots_equipment.base_equipment.quality}/10"
  puts "   Attributes: #{boots_equipment.nearby_attributes}"
  puts ''
  
  puts "💎 EMBEDDED GEMS:"
  embedded_gems = Gemstone.where(equipment_id: boots_equipment.id).order(:slot_number)
  embedded_gems.each do |gem|
    entry = gem.gemstone_entry
    puts "   Slot #{gem.slot_number}: #{entry.effect_name} Lv.#{gem.level} (#{entry["level_#{gem.level}_value"]})"
  end
  puts ''
end

# Count available gems by type
available_gems = Gemstone.where(
  player_id: player.id,
  part: 'Boots',
  is_in_inventory: true
)

gem_summary = available_gems.group(:level).joins(:gemstone_entry)
                           .group('gemstone_entries.effect_name')
                           .count

puts "📦 AVAILABLE BOOTS GEMS IN INVENTORY:"
gem_summary.each do |(level, effect_name), count|
  puts "   #{effect_name} Lv.#{level}: #{count} gems"
end

puts ''
puts "Total available boots gems: #{available_gems.count}"