#!/usr/bin/env rails runner

require 'benchmark'

puts "=" * 100
puts "DIAGNOSING BATTLE COMPLETION SLOWNESS"
puts "=" * 100
puts ""

player_id = 10
player = Player.find(player_id)

puts "[1] PLAYER TABLE SIZE AND STRUCTURE"
puts ""

puts "Player ##{player_id} attributes:"
puts "  ID: #{player.id}"
puts "  Items_JSON size: #{player.items_json.to_json.bytesize} bytes"
puts "  Draw times size: #{player.draw_times.to_json.bytesize} bytes"
puts "  Summoned allies size: #{player.summoned_allies.to_json.bytesize} bytes"
puts ""

puts "[2] RELATED DATA VOLUMES"
puts ""

sidekicks_count = Sidekick.where(player_id: player_id).count
equipments_count = Equipment.where(player_id: player_id).count
gemstones_count = Gemstone.where(player_id: player_id).count

puts "Sidekicks for player #{player_id}: #{sidekicks_count}"
puts "Equipments for player #{player_id}: #{equipments_count}"
puts "Gemstones for player #{player_id}: #{gemstones_count}"
puts ""

puts "[3] TIMING: player.reload (THE SLOW OPERATION)"
puts ""

time_ms = Benchmark.measure do
  Player.uncached { player.reload }
end.real * 1000

puts "  player.reload took: #{time_ms.round(2)}ms"

if time_ms > 100
  puts "  ⚠️  SLOW! Expected < 50ms for simple attribute load"
end

puts ""
puts "[4] TIMING: Build PlayerProfile"
puts ""

time_ms = Benchmark.measure do
  profile = PlayerProfile.new(player_id)
end.real * 1000

puts "  PlayerProfile.new took: #{time_ms.round(2)}ms"

puts ""
puts "[5] TIMING: PlayerProfile#as_ws_json"
puts ""

profile = PlayerProfile.new(player_id)
time_ms = Benchmark.measure do
  profile.as_ws_json
end.real * 1000

puts "  as_ws_json took: #{time_ms.round(2)}ms"

if time_ms > 500
  puts "  ⚠️  SLOW! Expected < 500ms for full profile generation"
end

puts ""
puts "[6] QUERY ANALYSIS: Check if Player has extra columns"
puts ""

player_columns = Player.columns
large_columns = player_columns.select { |col| col.type == :text || col.type == :json }

puts "Text/JSON columns:"
large_columns.each do |col|
  size_bytes = player.send(col.name).to_s.bytesize
  size_kb = (size_bytes / 1024.0).round(2)
  puts "  #{col.name}: #{size_bytes} bytes (#{size_kb} KB)"
end

puts ""
puts "[7] DATABASE INDEXES CHECK"
puts ""

# Check if there are indexes on player_id for related tables
tables_to_check = ['sidekicks', 'equipments', 'gemstones']

tables_to_check.each do |table|
  indexes = ActiveRecord::Base.connection.indexes(table.to_sym)
  player_id_indexes = indexes.select { |idx| idx.columns.include?('player_id') }

  if player_id_indexes.any?
    puts "✓ #{table}: Has index on player_id"
    player_id_indexes.each do |idx|
      puts "    - #{idx.name} (#{idx.columns.join(', ')})"
    end
  else
    puts "❌ #{table}: NO index on player_id! This causes N+1!"
  end
end

puts ""
puts "[8] CHECKING PLAYER TABLE INDEXES"
puts ""

player_indexes = ActiveRecord::Base.connection.indexes(:players)
if player_indexes.any?
  puts "Player table indexes:"
  player_indexes.each do |idx|
    puts "  - #{idx.name} (#{idx.columns.join(', ')})"
  end
else
  puts "❌ No indexes on players table!"
end

puts ""
puts "=" * 100
puts "ANALYSIS COMPLETE"
puts "=" * 100
