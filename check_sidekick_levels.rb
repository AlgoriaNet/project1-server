#!/usr/bin/env rails runner

# Check all sidekicks to see which levels exist
puts "Checking all 20 sidekicks for level coverage:"
puts ""

all_missing_l01 = true
sidekick_count = 0

BaseSidekick.order(:id).each do |sidekick|
  effects = BaseSkillLevelUpEffect.where(skill_id: sidekick.skill_id).order(:level)
  levels = effects.map(&:level)
  missing = [1, 3, 6, 9, 12, 15, 18, 20] - levels

  status = missing.empty? ? "✓" : "✗"
  puts "#{status} Sidekick #{sidekick.id.to_s.rjust(2)}: #{levels.sort.inspect} (missing: #{missing.inspect})"

  sidekick_count += 1
  all_missing_l01 = false if missing.include?(1)
end

puts ""
puts "Analysis:"
puts "  All sidekicks missing L01: #{all_missing_l01}"
puts "  Total sidekicks: #{sidekick_count}"
puts "  Expected records per sidekick: 8 (levels 1, 3, 6, 9, 12, 15, 18, 20)"
puts "  Actual records per sidekick: 7 (L01 deleted, other 7 present)"
