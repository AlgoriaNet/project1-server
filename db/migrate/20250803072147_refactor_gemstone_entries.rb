class RefactorGemstoneEntries < ActiveRecord::Migration[7.1]
  def up
    # Add base_value column
    add_column :gemstone_entries, :base_value, :decimal, precision: 8, scale: 2
    
    # Populate base_value with our professional values before removing old columns
    base_values = {
      1 => 100,   # HP
      2 => 30,    # Attack
      3 => 4,     # Critical rate %
      4 => 8,     # Critical damage %
      5 => 12,    # Gun damage %
      6 => 12,    # Fire damage %
      7 => 12,    # Ice damage %
      8 => 12,    # Wind damage %
      9 => 12,    # Light damage %
      10 => 12,   # Dark damage %
      11 => 12,   # Physical damage %
      12 => 6,    # Elite kill heal %
      13 => 25,   # Kill heal HP
      14 => 8,    # Low HP boost %
      15 => 10,   # Close range damage %
      16 => 2,    # Invincibility seconds
      17 => 15,   # Damage reduction %
      18 => 80,   # Auto damage points
      19 => 2,    # HP regen per second
      20 => 15,   # Gold per 10 kills
      21 => 8,    # Elite boost chance %
      22 => 10    # High HP damage %
    }
    
    base_values.each do |attr_id, base_value|
      execute "UPDATE gemstone_entries SET base_value = #{base_value} WHERE attribute_id = #{attr_id}"
    end
    
    # Remove obsolete columns
    remove_column :gemstone_entries, :level_1_value
    remove_column :gemstone_entries, :level_2_value
    remove_column :gemstone_entries, :level_3_value
    remove_column :gemstone_entries, :level_4_value
    remove_column :gemstone_entries, :level_5_value
    remove_column :gemstone_entries, :level_6_value
    remove_column :gemstone_entries, :level_7_value
    remove_column :gemstone_entries, :level_8_value
    remove_column :gemstone_entries, :level_9_value
    remove_column :gemstone_entries, :level_10_value
    remove_column :gemstone_entries, :growth_factor
  end
  
  def down
    # Reverse migration - add back old columns
    add_column :gemstone_entries, :level_1_value, :decimal, precision: 8, scale: 2
    add_column :gemstone_entries, :level_2_value, :decimal, precision: 8, scale: 2
    add_column :gemstone_entries, :level_3_value, :decimal, precision: 8, scale: 2
    add_column :gemstone_entries, :level_4_value, :decimal, precision: 8, scale: 2
    add_column :gemstone_entries, :level_5_value, :decimal, precision: 8, scale: 2
    add_column :gemstone_entries, :level_6_value, :decimal, precision: 8, scale: 2
    add_column :gemstone_entries, :level_7_value, :decimal, precision: 8, scale: 2
    add_column :gemstone_entries, :level_8_value, :decimal, precision: 8, scale: 2
    add_column :gemstone_entries, :level_9_value, :decimal, precision: 8, scale: 2
    add_column :gemstone_entries, :level_10_value, :decimal, precision: 8, scale: 2
    add_column :gemstone_entries, :growth_factor, :decimal, precision: 8, scale: 2
    
    # Remove base_value column
    remove_column :gemstone_entries, :base_value
  end
end
