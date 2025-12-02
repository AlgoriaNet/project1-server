# Daily Sign-In Rewards Configuration
# Seeds the reward data for all 30 days in a cycle

puts "Seeding Daily Sign-In Rewards..."

# Configure all 30 days
# Odd days (1, 3, 5, ...): 200 gold coin
# Even days (2, 4, 6, ...): 50 random skillbooks
# Milestone days (7, 14, 21, 30): special rewards

rewards = []

# Days 1-30 configuration
(1..30).each do |day|
  reward = {
    day_number: day,
    reward_type: nil,
    gold_coin: 0,
    skillbook_count: 0,
    diamond: 0,
    epic_key: 0,
    hero_key: 0,
    rare_key: 0
  }

  # Determine reward type and amounts
  case day
  when 7
    # Day 7 milestone: 30 diamonds (in addition to regular reward)
    reward[:reward_type] = "milestone"
    reward[:diamond] = 30
  when 14
    # Day 14 milestone: 10 epicKey
    reward[:reward_type] = "milestone"
    reward[:epic_key] = 10
  when 21
    # Day 21 milestone: 10 epicKey
    reward[:reward_type] = "milestone"
    reward[:epic_key] = 10
  when 30
    # Day 30 milestone: 10 heroKey + 10 rareKey + 10 epicKey
    reward[:reward_type] = "milestone"
    reward[:hero_key] = 10
    reward[:rare_key] = 10
    reward[:epic_key] = 10
  else
    # Regular days: alternate between gold and skillbooks
    if day.odd?
      # Odd days: 200 gold coin
      reward[:reward_type] = "gold_coin"
      reward[:gold_coin] = 200
    else
      # Even days: 50 random skillbooks
      reward[:reward_type] = "skillbooks"
      reward[:skillbook_count] = 50
    end
  end

  rewards << reward
end

# Create or update each reward
rewards.each do |reward_data|
  reward = DailySigninReward.find_or_initialize_by(day_number: reward_data[:day_number])

  reward.assign_attributes(reward_data)

  if reward.save
    case reward_data[:reward_type]
    when "gold_coin"
      puts "  Day #{reward.day_number}: #{reward.gold_coin} gold coin"
    when "skillbooks"
      puts "  Day #{reward.day_number}: #{reward.skillbook_count} random skillbooks"
    when "milestone"
      milestone_rewards = []
      milestone_rewards << "#{reward.diamond} diamonds" if reward.diamond > 0
      milestone_rewards << "#{reward.epic_key} epic keys" if reward.epic_key > 0
      milestone_rewards << "#{reward.hero_key} hero keys" if reward.hero_key > 0
      milestone_rewards << "#{reward.rare_key} rare keys" if reward.rare_key > 0
      puts "  Day #{reward.day_number} [MILESTONE]: #{milestone_rewards.join(', ')}"
    end
  else
    puts "  ERROR creating Day #{reward.day_number}: #{reward.errors.full_messages.join(', ')}"
  end
end

puts "\nDaily Sign-In Rewards seeding completed!"
puts "Total days configured: #{DailySigninReward.count}"
puts "Milestone days: #{DailySigninReward.where(reward_type: 'milestone').pluck(:day_number).join(', ')}"
puts "Gold coin days: #{DailySigninReward.where(reward_type: 'gold_coin').count}"
puts "Skillbook days: #{DailySigninReward.where(reward_type: 'skillbooks').count}"
