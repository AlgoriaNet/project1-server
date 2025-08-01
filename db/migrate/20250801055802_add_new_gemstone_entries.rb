class AddNewGemstoneEntries < ActiveRecord::Migration[7.1]
  def up
    # Columns already exist, just update data
    
    # Update existing entries with their growth factors and attribute info
    existing_entries = [
      { id: 33, effect_name: 'Hp', growth_factor: 0.3, attribute_id: 1 },
      { id: 34, effect_name: 'Suffered Damage', growth_factor: 0.18, attribute_id: 17 }, # This was actually advanced
      { id: 35, effect_name: 'Atk', growth_factor: 0.24, attribute_id: 2 },
      { id: 36, effect_name: 'Ctr', growth_factor: 0.12, attribute_id: 3 },
      { id: 37, effect_name: 'Cti', growth_factor: 0.24, attribute_id: 4 },
      { id: 38, effect_name: 'Mechanical', growth_factor: 0.24, attribute_id: 5 },
      { id: 39, effect_name: 'Light', growth_factor: 0.24, attribute_id: 9 },
      { id: 40, effect_name: 'Fire', growth_factor: 0.24, attribute_id: 6 },
      { id: 41, effect_name: 'Ice', growth_factor: 0.24, attribute_id: 7 },
      { id: 42, effect_name: 'Wind', growth_factor: 0.24, attribute_id: 8 },
      { id: 43, effect_name: 'Physics', growth_factor: 0.24, attribute_id: 11 },
      { id: 44, effect_name: 'Darkly', growth_factor: 0.24, attribute_id: 10 },
      { id: 45, effect_name: 'Heal', growth_factor: 0.18, attribute_id: 12 },
      { id: 46, effect_name: 'Damage', growth_factor: 0.18, attribute_id: 22 },
      { id: 47, effect_name: 'Cd', growth_factor: 0.12, attribute_id: 21 },
      { id: 48, effect_name: 'Penetrat', growth_factor: 0.18, attribute_id: 16 }
    ]
    
    existing_entries.each do |entry|
      execute <<-SQL
        UPDATE gemstone_entries 
        SET growth_factor = #{entry[:growth_factor]}, 
            attribute_id = #{entry[:attribute_id]},
            attribute_type = '#{entry[:attribute_id] <= 11 ? 'basic' : 'advanced'}'
        WHERE id = #{entry[:id]}
      SQL
    end
    
    # Insert new gemstone entries for missing attributes
    new_entries = [
      { effect_name: 'Elite Heal', effect_description: 'Recover defense HP when killing elite monsters', growth_factor: 0.18, attribute_id: 13, attribute_type: 'advanced' },
      { effect_name: 'Kill Heal', effect_description: 'Recover defense HP when killing any monster', growth_factor: 0.18, attribute_id: 14, attribute_type: 'advanced' },
      { effect_name: 'Low Hp Boost', effect_description: 'Increase skill attack as defense HP decreases', growth_factor: 0.18, attribute_id: 15, attribute_type: 'advanced' },
      { effect_name: 'Close Range', effect_description: 'Extra damage to monsters within 100 distance of defense', growth_factor: 0.18, attribute_id: 18, attribute_type: 'advanced' },
      { effect_name: 'Auto Strike', effect_description: 'Auto damage nearby monsters every 30 seconds', growth_factor: 0.12, attribute_id: 19, attribute_type: 'advanced' },
      { effect_name: 'Crisis Regen', effect_description: 'HP regeneration when defense HP below 20%', growth_factor: 0.18, attribute_id: 20, attribute_type: 'advanced' }
    ]
    
    new_entries.each do |entry|
      # Calculate level values using formula: Base(100) × Growth Factor × (Level²)
      level_1_value = 100 * entry[:growth_factor] * 1
      level_2_value = 100 * entry[:growth_factor] * 4
      level_3_value = 100 * entry[:growth_factor] * 9
      level_4_value = 100 * entry[:growth_factor] * 16
      level_5_value = 100 * entry[:growth_factor] * 25
      level_6_value = 100 * entry[:growth_factor] * 36
      level_7_value = 100 * entry[:growth_factor] * 49
      
      execute <<-SQL
        INSERT INTO gemstone_entries (
          effect_name, effect_description, growth_factor, attribute_id, attribute_type,
          level_1_value, level_2_value, level_3_value, level_4_value, 
          level_5_value, level_6_value, level_7_value,
          created_at, updated_at
        ) VALUES (
          '#{entry[:effect_name]}', '#{entry[:effect_description]}', 
          #{entry[:growth_factor]}, #{entry[:attribute_id]}, '#{entry[:attribute_type]}',
          #{level_1_value}, #{level_2_value}, 
          #{level_3_value}, #{level_4_value},
          #{level_5_value}, #{level_6_value}, 
          #{level_7_value},
          NOW(), NOW()
        )
      SQL
    end
    
    # Update existing entries to use formula-based values
    execute <<-SQL
      UPDATE gemstone_entries SET
        level_1_value = 100 * growth_factor * 1,
        level_2_value = 100 * growth_factor * 4,
        level_3_value = 100 * growth_factor * 9,
        level_4_value = 100 * growth_factor * 16,
        level_5_value = 100 * growth_factor * 25,
        level_6_value = 100 * growth_factor * 36,
        level_7_value = 100 * growth_factor * 49
      WHERE growth_factor IS NOT NULL
    SQL
  end

  def down
    # Reset existing entries
    execute <<-SQL
      UPDATE gemstone_entries SET growth_factor = NULL, attribute_type = NULL, attribute_id = NULL
    SQL
    
    # Delete new entries (keep existing ones)
    GemstoneEntry.where(effect_name: [
      'Elite Heal', 'Kill Heal', 'Low Hp Boost', 'Close Range',
      'Auto Strike', 'Crisis Regen'
    ]).destroy_all
  end
end
