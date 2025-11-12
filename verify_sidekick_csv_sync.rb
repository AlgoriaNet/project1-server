#!/usr/bin/env rails runner

require 'csv'

puts "=" * 100
puts "VERIFYING BASE_SIDEKICKS CSV vs DATABASE SYNC"
puts "=" * 100
puts ""

# Load CSV data
csv_file = File.expand_path('lib/config/base_sidekicks.csv', Rails.root)
csv_data = {}

File.readlines(csv_file).drop(2).each do |line|
  parts = line.strip.split(',')
  if parts.length >= 9
    id = parts[0].to_i
    csv_data[id] = {
      name: parts[1],
      skill_id: parts[2].to_i,
      character: parts[3],
      atk: parts[4].to_i,
      def: parts[5].to_i,
      cri: parts[6].to_i,
      crt: parts[7].to_i,
      variety_damage: parts[8].to_f
    }
  end
end

puts "[CSV Data Summary]"
puts "Loaded #{csv_data.size} sidekicks from CSV"
puts "ATK values in CSV: #{csv_data.values.map { |v| v[:atk] }.uniq.inspect}"
puts ""

puts "[Database vs CSV Comparison]"
puts ""

mismatches = []
matches = 0

BaseSidekick.order(:id).each do |sidekick|
  csv = csv_data[sidekick.id]

  if csv.nil?
    puts "⚠️  ID #{sidekick.id}: Not in CSV (#{sidekick.name})"
    next
  end

  # Compare each field
  fields_to_check = [:atk, :def, :cri, :crt, :variety_damage]
  has_mismatch = false
  mismatches_for_this = []

  fields_to_check.each do |field|
    db_value = sidekick.send(field)
    csv_value = csv[field]

    if db_value != csv_value
      has_mismatch = true
      mismatches_for_this << {
        field: field,
        db_value: db_value,
        csv_value: csv_value
      }
    end
  end

  if has_mismatch
    puts "❌ ID #{sidekick.id.to_s.rjust(2)}: #{sidekick.name}"
    mismatches_for_this.each do |m|
      puts "     #{m[:field].to_s.ljust(15)}: DB=#{m[:db_value]}, CSV=#{m[:csv_value]}"
    end
    mismatches << sidekick.id
  else
    matches += 1
  end
end

puts ""
puts "=" * 100
puts "SYNC STATUS"
puts "=" * 100
puts ""

if mismatches.empty?
  puts "✅ ALL SIDEKICKS SYNCHRONIZED WITH CSV"
  puts "  #{matches} sidekicks match CSV values perfectly"
  puts "  No database updates needed"
else
  puts "❌ FOUND #{mismatches.size} SIDEKICKS WITH MISMATCHES"
  puts "  IDs: #{mismatches.join(', ')}"
  puts "  Matches: #{matches}"
  puts ""
  puts "⚠️  These sidekicks need to be synced with CSV values!"
end

puts ""
puts "=" * 100
puts "DETAILED STAT COMPARISON TABLE"
puts "=" * 100
puts ""

printf "%-3s %-20s %-10s %-10s %-10s %-10s %-10s\n",
       "ID", "Name", "ATK", "DEF", "CRI", "CRT", "Variety"

puts "-" * 100

BaseSidekick.order(:id).each do |sidekick|
  csv = csv_data[sidekick.id]
  next unless csv

  # Show mismatches in red (using ✗ marker)
  atk_status = sidekick.atk == csv[:atk] ? "✓" : "✗"
  def_status = sidekick.def == csv[:def] ? "✓" : "✗"
  cri_status = sidekick.cri == csv[:cri] ? "✓" : "✗"
  crt_status = sidekick.crt == csv[:crt] ? "✓" : "✗"
  variety_status = sidekick.variety_damage == csv[:variety_damage] ? "✓" : "✗"

  printf "%-3d %-20s %s%-9d %s%-9d %s%-9d %s%-9d %s%-9.1f\n",
         sidekick.id,
         sidekick.name[0..19],
         atk_status,
         sidekick.atk,
         def_status,
         sidekick.def,
         cri_status,
         sidekick.cri,
         crt_status,
         sidekick.crt,
         variety_status,
         sidekick.variety_damage || 0.0
end

puts ""
puts "Legend: ✓ = Matches CSV, ✗ = Mismatch with CSV"
