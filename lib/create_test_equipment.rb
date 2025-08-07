# Create test equipment with varied intensify levels for frontend testing
class CreateTestEquipment
  def self.generate
    base_equipments = BaseEquipment.all
    player_id = 1  # Assuming player ID 1 exists
    
    # Create equipment with intensify_level 0-3 as requested in frontend message
    test_equipment = [
      { name_pattern: 'Orichalcum Helmet', intensify_level: 3 },
      { name_pattern: 'Mithril Boots', intensify_level: 1 },
      { name_pattern: 'Bronze Pants', intensify_level: 0 },
      { name_pattern: 'Iron Gloves', intensify_level: 0 },
      { name_pattern: 'Orichalcum Chestplate', intensify_level: 2 },
      { name_pattern: 'Orichalcum Shoulderpad', intensify_level: 1 },
      { name_pattern: 'Adamantite Pants', intensify_level: 0 },
      { name_pattern: 'Steel Boots', intensify_level: 0 },
      { name_pattern: 'Mithril Gloves', intensify_level: 1 },
      { name_pattern: 'Steel Helmet', intensify_level: 2 }
    ]
    
    test_equipment.each do |test_eq|
      base_eq = base_equipments.find { |be| be.name == test_eq[:name_pattern] }
      if base_eq
        equipment = Equipment.new(
          base_equipment_id: base_eq.id, 
          player_id: player_id, 
          intensify_level: test_eq[:intensify_level]
        )
        equipment.washing  # Apply random attributes
        equipment.save!
        puts "Created #{base_eq.name} (base_atk: #{base_eq.base_atk}, growth_atk: #{base_eq.growth_atk}) with intensify_level #{equipment.intensify_level}"
      else
        puts "Could not find base equipment: #{test_eq[:name_pattern]}"
      end
    end
    
    puts "\nTotal equipment created: #{Equipment.count}"
  end
end