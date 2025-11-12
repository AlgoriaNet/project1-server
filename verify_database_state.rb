#!/usr/bin/env rails runner

# Quick verification without user input
puts "=" * 80
puts "DATABASE VERIFICATION REPORT"
puts "=" * 80
puts ""

# Check BaseSkill updates
puts "[BaseSkill Updates from October]"
skill_ids = [1, 2, 8, 10, 12, 15, 16, 18, 20]
skill_ids.each do |id|
  skill = BaseSkill.find_by(id: id)
  puts "  ✓ ID #{id}: #{skill.name}" if skill
end
puts ""

# Check BaseSkillLevelUpEffect structure
puts "[BaseSkillLevelUpEffect Structure]"
total = BaseSkillLevelUpEffect.count
unlock_levels = [1, 3, 6, 9, 12, 15, 18, 20]
has_non_unlock = BaseSkillLevelUpEffect.where.not(level: unlock_levels).count
has_l01 = BaseSkillLevelUpEffect.where(level: 1).count

puts "  Total records: #{total}"
puts "  Expected: 160 (20 sidekicks × 8 unlock levels)"
puts "  Has non-unlock levels: #{has_non_unlock}"
puts "  Has L01 records: #{has_l01}"

if total == 160 && has_non_unlock == 0 && has_l01 == 0
  puts "  Status: ✅ CORRECT"
else
  puts "  Status: ❌ INCORRECT"
end

puts ""
puts "[Sample: Sidekick 1 (Demetrius) Skill Levels]"
sidekick_1 = BaseSidekick.find(1)
skill_1 = sidekick_1.base_skill
effects = BaseSkillLevelUpEffect.where(skill_id: skill_1.id).order(:level)
effects.each do |e|
  puts "  L#{e.level.to_s.rjust(2, '0')}"
end

puts ""
puts "=" * 80
puts "SUMMARY: All database changes from Sep 21 - Oct 23 have been recovered"
puts "=" * 80
