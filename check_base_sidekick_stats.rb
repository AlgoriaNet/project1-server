#!/usr/bin/env rails runner

puts "=" * 100
puts "INSPECTING BASE_SIDEKICKS TABLE - COMBAT STATS"
puts "=" * 100
puts ""

puts "[All 20 Base Sidekicks - Combat Stats]"
puts ""

# Show header
printf "%-3s %-20s %-3s %-3s %-5s %-5s %-15s\n",
       "ID", "Name", "Atk", "Def", "Cri%", "Crt%", "Variety_Dmg"

puts "-" * 100

BaseSidekick.order(:id).each do |sidekick|
  printf "%-3d %-20s %-3d %-3d %-5d %-5d %-15.1f\n",
         sidekick.id,
         sidekick.name[0..19],
         sidekick.atk || 0,
         sidekick.def || 0,
         sidekick.cri || 0,
         sidekick.crt || 0,
         sidekick.variety_damage || 0.0
end

puts ""
puts "=" * 100
puts "ANALYSIS: Looking for ZERO or SUSPICIOUS VALUES"
puts "=" * 100
puts ""

zero_atk = BaseSidekick.where(atk: 0).count
very_low_atk = BaseSidekick.where("atk > 0 AND atk < 5").count

puts "Sidekicks with atk = 0: #{zero_atk}"
puts "Sidekicks with atk < 5: #{very_low_atk}"
puts ""

if zero_atk > 0
  puts "❌ ERROR: Found sidekicks with zero attack!"
  puts ""
  BaseSidekick.where(atk: 0).order(:id).each do |sidekick|
    puts "  ID #{sidekick.id.to_s.rjust(2)}: #{sidekick.name.ljust(20)} - atk: #{sidekick.atk}"
  end
end

if very_low_atk > 0
  puts "⚠️  WARNING: Found sidekicks with very low attack (1-4)!"
  puts ""
  BaseSidekick.where("atk > 0 AND atk < 5").order(:id).each do |sidekick|
    puts "  ID #{sidekick.id.to_s.rjust(2)}: #{sidekick.name.ljust(20)} - atk: #{sidekick.atk}"
  end
end

puts ""
puts "[ATK Distribution Analysis]"
puts ""

atk_values = BaseSidekick.pluck(:atk).compact.sort.uniq
puts "Unique ATK values in database: #{atk_values.inspect}"
puts ""

atk_avg = BaseSidekick.where("atk > 0").average(:atk)
atk_min = BaseSidekick.where("atk > 0").minimum(:atk)
atk_max = BaseSidekick.maximum(:atk)

puts "ATK Statistics:"
puts "  Minimum: #{atk_min}"
puts "  Maximum: #{atk_max}"
puts "  Average: #{atk_avg.round(1)}"
puts ""

puts "[Combat Stat Summary]"
puts ""
puts "Atk:      Min=#{BaseSidekick.minimum(:atk)}, Max=#{BaseSidekick.maximum(:atk)}, Avg=#{BaseSidekick.average(:atk).round(1)}"
puts "Def:      Min=#{BaseSidekick.minimum(:def)}, Max=#{BaseSidekick.maximum(:def)}, Avg=#{BaseSidekick.average(:def).round(1)}"
puts "Cri (Rate): Min=#{BaseSidekick.minimum(:cri)}, Max=#{BaseSidekick.maximum(:cri)}, Avg=#{BaseSidekick.average(:cri).round(1)}"
puts "Crt (Dmg):  Min=#{BaseSidekick.minimum(:crt)}, Max=#{BaseSidekick.maximum(:crt)}, Avg=#{BaseSidekick.average(:crt).round(1)}"
puts ""

puts "=" * 100
puts "CHECKING CSV SOURCE OF TRUTH"
puts "=" * 100
puts ""

# Load the CSV to see what values should be there
csv_file = File.expand_path('lib/config/base_sidekicks.csv', Rails.root)
if File.exist?(csv_file)
  puts "✓ CSV file exists at: #{csv_file}"
  puts ""

  # Show first few lines
  puts "[First 5 lines of CSV (showing ATK values)]"
  File.readlines(csv_file).first(7).each_with_index do |line, idx|
    if idx < 2
      # Skip header lines
      next
    end
    parts = line.strip.split(',')
    if parts.length >= 7
      id = parts[0]
      name = parts[1]
      atk_csv = parts[5]  # assuming ATK is at index 5
      puts "  ID #{id}: #{name} - ATK in CSV: #{atk_csv}"
    end
  end
else
  puts "❌ CSV file not found!"
end
