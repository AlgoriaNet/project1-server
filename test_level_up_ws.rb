# Test script for LevelUpChannel WebSocket API

puts "=== Testing LevelUpChannel WebSocket API ==="

# Check if the channel class loads correctly
begin
  require_relative 'app/channels/level_up_channel'
  puts "✓ LevelUpChannel class loaded successfully"
rescue => e
  puts "✗ Failed to load LevelUpChannel: #{e.message}"
  exit 1
end

# Check if the CSV config loads correctly
begin
  costs = CsvConfig.load_level_up_costs
  puts "✓ Level up costs CSV loaded: #{costs.count} entries"
rescue => e
  puts "✗ Failed to load level up costs: #{e.message}"
  exit 1
end

# Check if we have players and sidekicks for testing
begin
  player_count = Player.count
  sidekick_count = Sidekick.count
  base_sidekick_count = BaseSidekick.count
  
  puts "✓ Database check:"
  puts "  - Players: #{player_count}"
  puts "  - Player sidekicks: #{sidekick_count}" 
  puts "  - Base sidekicks: #{base_sidekick_count}"
  
  if player_count == 0
    puts "⚠ Warning: No players in database - cannot test player-specific functionality"
  end
  
  if sidekick_count == 0
    puts "⚠ Warning: No player sidekicks in database - level up will fail"
  end
  
rescue => e
  puts "✗ Database check failed: #{e.message}"
end

puts "\n=== WebSocket API Ready ==="
puts "Channel: LevelUpChannel"
puts "Actions:"
puts "  - get_level_up_cost(json) - Check level and costs"
puts "  - level_up_ally(json) - Execute level up"
puts "\nParameter format:"
puts "  {ally_id: '04_Aurelia'}"
# Get max level from CSV
costs = CsvConfig.load_level_up_costs
max_level = costs.map { |cost| cost[:level] }.max
puts "\nMax level: #{max_level} (dynamic from CSV)"