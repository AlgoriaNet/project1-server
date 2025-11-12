#!/usr/bin/env rails runner

puts "=" * 100
puts "INSPECTING BASE_SIDEKICKS TABLE - ALL STATS"
puts "=" * 100
puts ""

puts "[All 20 Base Sidekicks - Full Stats]"
puts ""

# Show header
printf "%-3s %-20s %-3s %-4s %-4s %-4s %-5s %-5s %-5s %-5s %-5s\n",
       "ID", "Name", "Atk", "Def", "Hp", "Spd", "CritR", "CritD", "Hit%", "Dodge", "Block"

puts "-" * 100

BaseSidekick.order(:id).each do |sidekick|
  printf "%-3d %-20s %-3s %-4s %-4s %-4s %-5s %-5s %-5s %-5s %-5s\n",
         sidekick.id,
         sidekick.name[0..19],
         sidekick.atk.to_s,
         sidekick.def.to_s,
         sidekick.hp.to_s,
         sidekick.spd.to_s,
         (sidekick.crit_rate || 0).to_s,
         (sidekick.crit_damage || 0).to_s,
         (sidekick.hit_rate || 0).to_s,
         (sidekick.dodge_rate || 0).to_s,
         (sidekick.block_rate || 0).to_s
end

puts ""
puts "=" * 100
puts "ANALYSIS: Looking for ZERO or LOW atk values"
puts "=" * 100
puts ""

zero_atk = BaseSidekick.where(atk: 0).count
low_atk = BaseSidekick.where("atk < 10").count

puts "Sidekicks with atk = 0: #{zero_atk}"
puts "Sidekicks with atk < 10: #{low_atk}"

if zero_atk > 0
  puts ""
  puts "⚠️  WARNING: Found sidekicks with zero attack!"
  puts ""
  BaseSidekick.where(atk: 0).each do |sidekick|
    puts "  ID #{sidekick.id}: #{sidekick.name} - atk: #{sidekick.atk}"
  end
end

if low_atk > 0 && zero_atk == 0
  puts ""
  puts "⚠️  WARNING: Found sidekicks with very low attack (< 10)!"
  puts ""
  BaseSidekick.where("atk < 10").each do |sidekick|
    puts "  ID #{sidekick.id}: #{sidekick.name} - atk: #{sidekick.atk}"
  end
end

puts ""
puts "=" * 100
puts "CHECKING FOR ZERO VALUES IN OTHER STATS"
puts "=" * 100
puts ""

%w[def hp spd crit_rate crit_damage hit_rate dodge_rate block_rate].each do |stat|
  count = BaseSidekick.where("#{stat} = 0").count
  if count > 0
    puts "⚠️  #{stat.upcase}: #{count} sidekicks with zero value"
  end
end

puts ""
puts "=" * 100
puts "DETAILED VIEW: Sidekicks with potential issues"
puts "=" * 100
puts ""

BaseSidekick.order(:id).each do |sidekick|
  has_issue = false
  issues = []

  issues << "atk=0" if sidekick.atk == 0
  issues << "atk<10" if sidekick.atk && sidekick.atk < 10
  issues << "def=0" if sidekick.def == 0
  issues << "hp=0" if sidekick.hp == 0
  issues << "spd=0" if sidekick.spd == 0

  if issues.any?
    puts "ID #{sidekick.id}: #{sidekick.name}"
    puts "  Issues: #{issues.join(', ')}"
    puts "  Stats: atk=#{sidekick.atk}, def=#{sidekick.def}, hp=#{sidekick.hp}, spd=#{sidekick.spd}"
    puts ""
  end
end
