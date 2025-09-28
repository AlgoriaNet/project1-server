puts 'Fixing BaseSkillLevelUpEffect data format - converting integers to strings...'

count = 0
BaseSkillLevelUpEffect.find_each do |effect|
  # Parse the current effects JSON
  effects_data = JSON.parse(effect.effects)

  # Convert all values to strings
  fixed_effects = {}
  effects_data.each do |key, value|
    fixed_effects[key] = value.to_s
  end

  # Update the record
  effect.update!(effects: fixed_effects.to_json)
  count += 1
end

puts "Fixed #{count} BaseSkillLevelUpEffect records"

# Verify the fix
sample = BaseSkillLevelUpEffect.first
puts "Sample fixed effects: #{sample.effects}"

# Test that it can be parsed properly
parsed = JSON.parse(sample.effects)
puts "Sample parsed: #{parsed.inspect}"
puts "All values are strings: #{parsed.values.all? { |v| v.is_a?(String) }}"