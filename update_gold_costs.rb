# Update existing upgrade data with gold costs
# Gold costs are typically higher than skill book costs

upgrades = [
  {level: 2, gold_cost: 200},   # Skill book: 50, Gold: 200
  {level: 6, gold_cost: 500},   # Skill book: 100, Gold: 500
  {level: 8, gold_cost: 1000},  # Skill book: 200, Gold: 1000
  {level: 15, gold_cost: 2000}, # Skill book: 300, Gold: 2000
  {level: 20, gold_cost: 3000}  # Skill book: 500, Gold: 3000
]

upgrades.each do |upgrade|
  effect = BaseSkillLevelUpEffect.find_by(skill_id: 1, level: upgrade[:level])
  if effect
    effect.update!(gold_cost: upgrade[:gold_cost])
    puts "Updated level #{upgrade[:level]} with gold cost #{upgrade[:gold_cost]}"
  else
    puts "Could not find upgrade for level #{upgrade[:level]}"
  end
end

puts "Updated #{BaseSkillLevelUpEffect.where.not(gold_cost: nil).count} upgrades with gold costs"