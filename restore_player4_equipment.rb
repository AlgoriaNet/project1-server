# Restore Player 4's equipment using safe methods
base_equipments = BaseEquipment.all
player_id = 4

# Create a variety of equipment across all qualities and intensify levels
equipment_list = [
  # Bronze Equipment (Quality 1)
  { name: 'Shoulder_01', intensify_level: 0, upgrade_rank: 0 },
  { name: 'Pants_01', intensify_level: 1, upgrade_rank: 1 },
  
  # Iron Equipment (Quality 2)  
  { name: 'Chest_02', intensify_level: 2, upgrade_rank: 2 },
  { name: 'Gloves_02', intensify_level: 1, upgrade_rank: 1 },
  { name: 'Helm_02', intensify_level: 0, upgrade_rank: 0 },
  
  # Steel Equipment (Quality 3)
  { name: 'Boots_03', intensify_level: 3, upgrade_rank: 2 },
  { name: 'Shoulder_03', intensify_level: 2, upgrade_rank: 1 },
  { name: 'Pants_03', intensify_level: 1, upgrade_rank: 3 },
  
  # Mithril Equipment (Quality 4)
  { name: 'Chest_04', intensify_level: 4, upgrade_rank: 3 },
  { name: 'Gloves_04', intensify_level: 3, upgrade_rank: 2 },
  { name: 'Helm_04', intensify_level: 2, upgrade_rank: 4 },
  { name: 'Boots_04', intensify_level: 1, upgrade_rank: 1 },
  
  # Adamantite Equipment (Quality 5) 
  { name: 'Shoulder_05', intensify_level: 5, upgrade_rank: 4 },
  { name: 'Pants_05', intensify_level: 4, upgrade_rank: 3 },
  { name: 'Chest_05', intensify_level: 3, upgrade_rank: 5 },
  
  # Orichalcum Equipment (Quality 6)
  { name: 'Gloves_06', intensify_level: 6, upgrade_rank: 5 },
  { name: 'Helm_06', intensify_level: 5, upgrade_rank: 4 },
  { name: 'Boots_06', intensify_level: 4, upgrade_rank: 6 }
]

equipment_list.each do |eq_data|
  base_eq = base_equipments.find { |be| be.name == eq_data[:name] }
  if base_eq
    equipment = Equipment.new(
      base_equipment_id: base_eq.id,
      player_id: player_id,
      intensify_level: eq_data[:intensify_level],
      upgrade_rank: eq_data[:upgrade_rank]
    )
    equipment.washing  # Apply random attributes
    equipment.save!
    puts "Created #{base_eq.display_name} (#{base_eq.name}) with intensify_level #{equipment.intensify_level}, upgrade_rank #{equipment.upgrade_rank}"
  else
    puts "Could not find base equipment: #{eq_data[:name]}"
  end
end

puts "\nTotal equipment for Player 4: #{Equipment.where(player_id: player_id).count}"