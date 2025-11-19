# Membership Card Rewards Configuration
# Seeds the reward data for weekly and monthly membership cards

puts "Seeding Membership Card Rewards..."

membership_card_rewards = [
  {
    card_type: 'weekly',
    diamond_one_time: 680,
    diamond_per_day: 0,
    gold_per_day: 200,
    rarekey_per_day: 1,
    epickey_per_day: 1,
    stamina_per_day: 0
  },
  {
    card_type: 'monthly',
    diamond_one_time: 2040,
    diamond_per_day: 80,
    gold_per_day: 200,
    rarekey_per_day: 0,
    epickey_per_day: 0,
    stamina_per_day: 100
  }
]

# Create or update each membership card reward configuration
membership_card_rewards.each do |reward_data|
  reward = MembershipCardReward.find_or_initialize_by(card_type: reward_data[:card_type])

  reward.assign_attributes(reward_data)

  if reward.save
    puts "  Created/Updated #{reward.card_type.upcase} card: #{reward.diamond_one_time} diamonds one-time, #{reward.gold_per_day} gold/day"
  else
    puts "  ERROR creating #{reward_data[:card_type]} card: #{reward.errors.full_messages.join(', ')}"
  end
end

puts "Membership Card Rewards seeding completed!"
puts "Total membership card configurations: #{MembershipCardReward.count}"
