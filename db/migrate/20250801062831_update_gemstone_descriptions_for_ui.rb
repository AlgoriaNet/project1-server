class UpdateGemstoneDescriptionsForUi < ActiveRecord::Migration[7.1]
  def up
    # Update existing entries with succinct, UI-friendly descriptions
    updates = [
      # Basic attributes (1-11)
      { id: 33, effect_name: 'Hp', description: 'Max HP' },
      { id: 35, effect_name: 'Atk', description: 'Attack damage' },
      { id: 36, effect_name: 'Ctr', description: 'Critical rate' },
      { id: 37, effect_name: 'Cti', description: 'Critical damage' },
      { id: 38, effect_name: 'Mechanical', description: 'Gun damage' },
      { id: 40, effect_name: 'Fire', description: 'Fire damage' },
      { id: 41, effect_name: 'Ice', description: 'Ice damage' },
      { id: 42, effect_name: 'Wind', description: 'Wind damage' },
      { id: 39, effect_name: 'Light', description: 'Light damage' },
      { id: 44, effect_name: 'Darkly', description: 'Dark damage' },
      { id: 43, effect_name: 'Physics', description: 'Physical damage' },
      
      # Advanced attributes (12-22) 
      { id: 34, effect_name: 'SufferedDamage', description: 'Damage reduction' },
      { id: 45, effect_name: 'Heal', description: 'Healing bonus' },
      { id: 47, effect_name: 'Cd', description: 'Cooldown reduction' },
      { id: 48, effect_name: 'Penetrat', description: 'Armor penetration' },
      { id: 46, effect_name: 'Damage', description: 'Overall damage' },
      
      # New advanced attributes
      { effect_name: 'Elite Heal', description: 'HP from elite kills' },
      { effect_name: 'Kill Heal', description: 'HP from kills' },
      { effect_name: 'Low Hp Boost', description: 'Skill boost when low HP' },
      { effect_name: 'Close Range', description: 'Close range damage' },
      { effect_name: 'Auto Strike', description: 'Auto damage nearby' },
      { effect_name: 'Crisis Regen', description: 'Crisis HP regen' }
    ]
    
    updates.each do |update|
      if update[:id]
        # Update by ID for existing entries
        execute <<-SQL
          UPDATE gemstone_entries 
          SET effect_description = '#{update[:description]}'
          WHERE id = #{update[:id]}
        SQL
      else
        # Update by name for new entries
        execute <<-SQL
          UPDATE gemstone_entries 
          SET effect_description = '#{update[:description]}'
          WHERE effect_name = '#{update[:effect_name]}'
        SQL
      end
    end
  end

  def down
    # Restore original descriptions
    execute <<-SQL
      UPDATE gemstone_entries SET
        effect_description = CASE effect_name
          WHEN 'Hp' THEN 'Increases maximum health points'
          WHEN 'Atk' THEN 'Increases attack damage'
          WHEN 'Ctr' THEN 'Increases critical hit rate'
          WHEN 'Cti' THEN 'Increases critical hit damage'
          WHEN 'Mechanical' THEN 'Adds mechanical damage to attacks'
          WHEN 'Fire' THEN 'Adds fire damage to attacks'
          WHEN 'Ice' THEN 'Adds ice damage to attacks'
          WHEN 'Wind' THEN 'Adds wind damage to attacks'
          WHEN 'Light' THEN 'Adds light damage to attacks'
          WHEN 'Darkly' THEN 'Adds dark damage to attacks'
          WHEN 'Physics' THEN 'Adds physical damage to attacks'
          WHEN 'SufferedDamage' THEN 'Reduces incoming damage'
          WHEN 'Heal' THEN 'Increases healing effectiveness'
          WHEN 'Cd' THEN 'Reduces skill cooldown time'
          WHEN 'Penetrat' THEN 'Increases armor penetration'
          WHEN 'Damage' THEN 'Increases overall damage output'
          WHEN 'Elite Heal' THEN 'Recover defense HP when killing elite monsters'
          WHEN 'Kill Heal' THEN 'Recover defense HP when killing any monster'
          WHEN 'Low Hp Boost' THEN 'Increase skill attack as defense HP decreases'
          WHEN 'Close Range' THEN 'Extra damage to monsters within 100 distance of defense'
          WHEN 'Auto Strike' THEN 'Auto damage nearby monsters every 30 seconds'
          WHEN 'Crisis Regen' THEN 'HP regeneration when defense HP below 20%'
          ELSE effect_description
        END
    SQL
  end
end
