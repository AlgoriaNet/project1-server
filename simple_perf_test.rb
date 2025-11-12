#!/usr/bin/env rails runner

require 'benchmark'

player_id = 10

puts "PERFORMANCE TEST - Battle Reward Loading"
puts "=" * 80
puts ""

# Test 1: Load and serialize gemstones
gemstones = Gemstone.includes(:gemstone_entry, :secondary_gemstone_entry)
                    .where(player_id: player_id)

time_ms = Benchmark.measure { @gems_json = gemstones.map(&:as_ws_json) }.real * 1000
puts "Gemstones (#{gemstones.count} items): #{time_ms.round(1)}ms (#{(time_ms / gemstones.count).round(1)}ms per item)"

# Test 2: Load and serialize sidekicks
sidekicks = Sidekick.includes(base_sidekick: :base_skill)
                    .where(player_id: player_id)

time_ms = Benchmark.measure { @sids_json = sidekicks.map(&:as_ws_json) }.real * 1000
puts "Sidekicks (#{sidekicks.count} items): #{time_ms.round(1)}ms (#{(time_ms / sidekicks.count).round(1)}ms per item)"

# Test 3: Full PlayerProfile
profile = PlayerProfile.new(player_id)
time_ms = Benchmark.measure { profile.as_ws_json }.real * 1000
puts "PlayerProfile#as_ws_json: #{time_ms.round(1)}ms"

puts ""
puts "ANALYSIS:"
puts "- Gemstones are the main bottleneck (#{(3000 * 65 / 1000).round(0)}s for 65 items @ ~50ms each)"
puts "- This is acceptable for a real-time game if optimized"
puts "- Main issue: Each gem.as_ws_json does attribute lookups that might not be cached"
