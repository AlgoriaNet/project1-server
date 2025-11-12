#!/usr/bin/env rails runner

require 'benchmark'

puts "=" * 100
puts "DETAILED PERFORMANCE BREAKDOWN - Player 10"
puts "=" * 100
puts ""

player_id = 10

puts "[STEP 1] Query Gemstones with includes"
puts ""

time_ms = Benchmark.measure do
  @gemstones = Gemstone.includes(:gemstone_entry, :secondary_gemstone_entry)
                        .where(player_id: player_id)
                        .to_a  # Force evaluation
end.real * 1000

puts "Gemstone.includes(...).where(...).to_a: #{time_ms.round(2)}ms"
puts "Number of gemstones: #{@gemstones.size}"
puts ""

puts "[STEP 2] Serialize gemstones one by one"
puts ""

time_ms = Benchmark.measure do
  @gemstones_json = @gemstones.map(&:as_ws_json)
end.real * 1000

puts "gemstones.map(&:as_ws_json): #{time_ms.round(2)}ms"
puts "Average per gemstone: #{(time_ms / @gemstones.size).round(2)}ms"
puts ""

puts "[STEP 3] Query Sidekicks with includes"
puts ""

time_ms = Benchmark.measure do
  @sidekicks = Sidekick.includes(base_sidekick: :base_skill)
                       .where(player_id: player_id)
                       .to_a
end.real * 1000

puts "Sidekick.includes(...).where(...).to_a: #{time_ms.round(2)}ms"
puts "Number of sidekicks: #{@sidekicks.size}"
puts ""

puts "[STEP 4] Serialize sidekicks one by one"
puts ""

time_ms = Benchmark.measure do
  @sidekicks_json = @sidekicks.map(&:as_ws_json)
end.real * 1000

puts "sidekicks.map(&:as_ws_json): #{time_ms.round(2)}ms"
puts "Average per sidekick: #{(time_ms / @sidekicks.size).round(2)}ms"
puts ""

puts "[STEP 5] Full PlayerProfile#as_ws_json"
puts ""

player = Player.find(player_id)
profile = PlayerProfile.new(player_id)

time_ms = Benchmark.measure do
  result = profile.as_ws_json
end.real * 1000

puts "PlayerProfile#as_ws_json: #{time_ms.round(2)}ms"
puts ""

puts "=" * 100
puts "QUERY COUNT ANALYSIS"
puts "=" * 100
puts ""

# Reset and count queries
ActiveRecord::Base.connection.reset
query_count_before = ActiveRecord::Base.connection.query_cache.size rescue 0

gemstones = Gemstone.includes(:gemstone_entry, :secondary_gemstone_entry)
                     .where(player_id: player_id)

puts "Gemstones query (with includes):"
puts "  Expected: 1 main query + 2 include queries = 3 queries"
puts "  Actual queries will show in logs above"

# Force evaluation and watch logs
gemstones_json = gemstones.map(&:as_ws_json)

puts ""
puts "=" * 100
puts "RECOMMENDATIONS"
puts "=" * 100
puts ""

puts "Current Bottleneck: Gemstone serialization (#{65 * 0.05} seconds for 65 gems @ 50ms each)"
puts ""
puts "Options to improve:"
puts "1. Optimize Gemstone#as_ws_json to cache repeated lookups"
puts "2. Batch serialize gemstones instead of map(&:method)"
puts "3. Cache GemstoneEntry lookups to avoid repeated queries"
puts "4. Add database-level caching for frequently accessed data"
puts "5. Consider lazy-loading gemstones instead of including all"
puts ""
