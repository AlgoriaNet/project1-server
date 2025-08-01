class MakeDescriptionsMoreConcise < ActiveRecord::Migration[7.1]
  def up
    # Make descriptions shorter but keep essential mechanics
    concise_descriptions = [
      # ID 12: 杀死精英怪回复防线血量
      { attribute_id: 12, description: 'Defense HP from elite kills' },
      
      # ID 13: 杀死一只怪后回复防线血量  
      { attribute_id: 13, description: 'Defense HP from kills' },
      
      # ID 14: 防线血量每降低10%，提高技能攻击
      { attribute_id: 14, description: 'Skill attack per 10% HP lost' },
      
      # ID 15: 对距离防线100以内的怪+N%伤害
      { attribute_id: 15, description: 'Damage to enemies within 100 range' },
      
      # ID 16: 防线受到伤害激活无敌状态，持续N秒
      { attribute_id: 16, description: 'Invincibility on damage, lasts' },
      
      # ID 17: 当场上怪物数量超过N只时，防线收到的伤害-N
      { attribute_id: 17, description: 'Damage reduction when enemies exceed' },
      
      # ID 18: 每过30s秒，自动对距离防线50以内的怪物造成 N 点伤害
      { attribute_id: 18, description: 'Auto damage within 50 range every 30s' },
      
      # ID 19: 当防线血量低于 20% 时，防线每秒回复N血量，持续300s
      { attribute_id: 19, description: 'HP regen/sec when below 20% (300s)' },
      
      # ID 20: 每击杀10只怪物，获得1金币
      { attribute_id: 20, description: 'Gold per 10 kills' },
      
      # ID 21: 击杀精英怪后，有N% 概率获得攻击增加N%
      { attribute_id: 21, description: 'Attack boost chance from elite kills' },
      
      # ID 22: 对血量高于70%的怪+N%伤害
      { attribute_id: 22, description: 'Damage to enemies above 70% HP' }
    ]
    
    concise_descriptions.each do |desc|
      execute <<-SQL
        UPDATE gemstone_entries 
        SET effect_description = '#{desc[:description]}'
        WHERE attribute_id = #{desc[:attribute_id]}
      SQL
    end
  end

  def down
    # Restore previous longer descriptions
    execute <<-SQL
      UPDATE gemstone_entries SET
        effect_description = CASE attribute_id
          WHEN 12 THEN 'Recover defense HP when killing elite monsters'
          WHEN 13 THEN 'Recover defense HP when killing any monster'
          WHEN 14 THEN 'Skill attack increases for every 10% defense HP lost'
          WHEN 15 THEN 'Extra damage to enemies within 100 range of defense'
          WHEN 16 THEN 'Defense invincibility when taking damage, lasts'
          WHEN 17 THEN 'Defense damage reduction when enemy count exceeds'
          WHEN 18 THEN 'Auto deal damage to enemies within 50 range every 30s'
          WHEN 19 THEN 'Defense HP regen per second when below 20%, lasts 300s'
          WHEN 20 THEN 'Gain 1 gold coin for every 10 monsters killed'
          WHEN 21 THEN 'Chance to gain attack boost after killing elite monster'
          WHEN 22 THEN 'Extra damage to enemies with HP above 70%'
          ELSE effect_description
        END
      WHERE attribute_id BETWEEN 12 AND 22
    SQL
  end
end
