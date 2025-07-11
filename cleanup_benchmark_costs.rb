# Remove wrong benchmark costs and clean up base_skill_level_up_effects
# The costs should come from the new level_up_costs.csv instead

puts "=== CLEANING UP WRONG BENCHMARK COSTS ==="

# Clear the weight and gold_cost fields from all upgrade effects
# These were wrongly populated - costs should be universal, not per benchmark level
puts "Clearing weight and gold_cost fields from base_skill_level_up_effects..."

BaseSkillLevelUpEffect.update_all(weight: 0, gold_cost: nil)

puts "Cleared cost fields from #{BaseSkillLevelUpEffect.count} upgrade effects"

# Test the new CSV loader
puts "\n=== TESTING NEW LEVEL UP COSTS CSV ==="
begin
  costs = CsvConfig.load_level_up_costs
  puts "Successfully loaded #{costs.count} level up cost entries"
  
  # Show first few entries
  costs.first(5).each do |cost|
    puts "Level #{cost[:level]}: #{cost[:skillbook_cost]} skillbooks, #{cost[:gold_cost]} gold"
  end
  
  puts "..."
  puts "Level #{costs.last[:level]}: #{costs.last[:skillbook_cost]} skillbooks, #{costs.last[:gold_cost]} gold"
  
rescue => e
  puts "ERROR loading CSV: #{e.message}"
end

puts "\n=== CLEANUP COMPLETE ==="
puts "- Removed wrong benchmark costs from upgrade effects"
puts "- Added universal level_up_costs.csv configuration"
puts "- Updated CsvConfig to load the new cost data"