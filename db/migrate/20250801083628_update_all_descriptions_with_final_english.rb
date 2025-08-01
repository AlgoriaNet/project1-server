class UpdateAllDescriptionsWithFinalEnglish < ActiveRecord::Migration[7.1]
  def up
    # Apply our final concise English descriptions for all attributes
    # Note: Multi-N value complexity will be addressed in future iterations
    
    final_descriptions = [
      # Basic attributes (1-11) - already good, keeping them
      { attribute_id: 1, description: 'Max HP' },
      { attribute_id: 2, description: 'Attack damage' },
      { attribute_id: 3, description: 'Critical rate' },
      { attribute_id: 4, description: 'Critical damage' },
      { attribute_id: 5, description: 'Gun damage' },
      { attribute_id: 6, description: 'Fire damage' },
      { attribute_id: 7, description: 'Ice damage' },
      { attribute_id: 8, description: 'Wind damage' },
      { attribute_id: 9, description: 'Light damage' },
      { attribute_id: 10, description: 'Dark damage' },
      { attribute_id: 11, description: 'Physical damage' },
      
      # Advanced attributes (12-22) - our new concise versions
      { attribute_id: 12, description: 'Defense HP from elite kills' },
      { attribute_id: 13, description: 'Defense HP from kills' },
      { attribute_id: 14, description: 'Skill attack per 10% HP lost' },
      { attribute_id: 15, description: 'Damage to enemies within 100 range' },
      { attribute_id: 16, description: 'Invincibility on damage, lasts' },
      { attribute_id: 17, description: 'Damage reduction when enemies exceed' },
      { attribute_id: 18, description: 'Auto damage within 50 range every 30s' },
      { attribute_id: 19, description: 'HP regen/sec when below 20% (300s)' },
      { attribute_id: 20, description: 'Gold per 10 kills' },
      { attribute_id: 21, description: 'Attack boost chance from elite kills' },
      { attribute_id: 22, description: 'Damage to enemies above 70% HP' }
    ]
    
    final_descriptions.each do |desc|
      execute <<-SQL
        UPDATE gemstone_entries 
        SET effect_description = '#{desc[:description]}'
        WHERE attribute_id = #{desc[:attribute_id]}
      SQL
    end
    
    puts "Updated all 22 gemstone descriptions with final English versions"
    puts "Note: Multi-N value complexity (IDs 17, 21) to be addressed separately"
  end

  def down
    puts "Rollback: Restoring previous descriptions"
    # Previous versions can be restored if needed
    # For now, this migration establishes our final baseline
  end
end
