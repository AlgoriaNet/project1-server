class AddMonsterAttributes < ActiveRecord::Migration[7.1]
  def change
    add_column :monsters, :size, :string
    add_column :monsters, :elemental_weakness, :string
    add_column :monsters, :movement_speed_multiplier, :float
    add_column :monsters, :attack_range, :float  
    add_column :monsters, :special_abilities, :json
    add_column :monsters, :habitat_levels, :json
    add_column :monsters, :spawn_probability, :json
    add_column :monsters, :is_boss, :boolean, default: false
    add_column :monsters, :is_elite, :boolean, default: false
  end
end
