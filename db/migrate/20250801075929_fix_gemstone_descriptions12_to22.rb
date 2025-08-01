class FixGemstoneDescriptions12To22 < ActiveRecord::Migration[7.1]
  def up
    # Fix all descriptions for attributes 12-22 with proper English preserving all mechanics
    corrections = [
      # ID 12: 杀死精英怪回复防线血量
      { attribute_id: 12, description: 'Recover defense HP when killing elite monsters' },
      
      # ID 13: 杀死一只怪后回复防线血量  
      { attribute_id: 13, description: 'Recover defense HP when killing any monster' },
      
      # ID 14: 防线血量每降低10%，提高技能攻击
      { attribute_id: 14, description: 'Skill attack increases for every 10% defense HP lost' },
      
      # ID 15: 对距离防线100以内的怪+N%伤害
      { attribute_id: 15, description: 'Extra damage to enemies within 100 range of defense' },
      
      # ID 16: 防线受到伤害激活无敌状态，持续N秒
      { attribute_id: 16, description: 'Defense invincibility when taking damage, lasts' },
      
      # ID 17: 当场上怪物数量超过N只时，防线收到的伤害-N
      { attribute_id: 17, description: 'Defense damage reduction when enemy count exceeds' },
      
      # ID 18: 每过30s秒，自动对距离防线50以内的怪物造成 N 点伤害
      { attribute_id: 18, description: 'Auto deal damage to enemies within 50 range every 30s' },
      
      # ID 19: 当防线血量低于 20% 时，防线每秒回复N血量，持续300s
      { attribute_id: 19, description: 'Defense HP regen per second when below 20%, lasts 300s' },
      
      # ID 20: 每击杀10只怪物，获得1金币
      { attribute_id: 20, description: 'Gain 1 gold coin for every 10 monsters killed' },
      
      # ID 21: 击杀精英怪后，有N% 概率获得攻击增加N%
      { attribute_id: 21, description: 'Chance to gain attack boost after killing elite monster' },
      
      # ID 22: 对血量高于70%的怪+N%伤害
      { attribute_id: 22, description: 'Extra damage to enemies with HP above 70%' }
    ]
    
    corrections.each do |correction|
      execute <<-SQL
        UPDATE gemstone_entries 
        SET effect_description = '#{correction[:description]}'
        WHERE attribute_id = #{correction[:attribute_id]}
      SQL
    end
  end

  def down
    # Restore the previous (incorrect) descriptions
    execute <<-SQL
      UPDATE gemstone_entries SET
        effect_description = CASE attribute_id
          WHEN 12 THEN 'Healing bonus'
          WHEN 13 THEN 'HP from elite kills'
          WHEN 14 THEN 'HP from kills'
          WHEN 15 THEN 'Skill boost when low HP'
          WHEN 16 THEN 'Armor penetration'
          WHEN 17 THEN 'Damage reduction'
          WHEN 18 THEN 'Close range damage'
          WHEN 19 THEN 'Auto damage nearby'
          WHEN 20 THEN 'Crisis HP regen'
          WHEN 21 THEN 'Cooldown reduction'
          WHEN 22 THEN 'Overall damage'
          ELSE effect_description
        END
      WHERE attribute_id BETWEEN 12 AND 22
    SQL
  end
end
