# First Charge Tier Rewards Configuration
# Seeds the reward data for all three tiers and three days

puts "Seeding First Charge Tier Rewards..."

# Eleanor's sidekick ID
ELEANOR_SIDEKICK_ID = 19

# Tier 1: $14.99
tier_1_rewards = [
  {
    tier: 1,
    day: 1,
    sidekick_id: ELEANOR_SIDEKICK_ID,
    diamond: 100,
    rarekey_count: 30,
    epickey_count: 0,
    skillbook_count: 0,
    shard_count: 10
  },
  {
    tier: 1,
    day: 2,
    sidekick_id: nil,
    diamond: 100,
    rarekey_count: 0,
    epickey_count: 20,
    skillbook_count: 0,
    shard_count: 10
  },
  {
    tier: 1,
    day: 3,
    sidekick_id: nil,
    diamond: 100,
    rarekey_count: 0,
    epickey_count: 0,
    skillbook_count: 100,
    shard_count: 10
  }
]

# Tier 2: $4.99
tier_2_rewards = [
  {
    tier: 2,
    day: 1,
    sidekick_id: ELEANOR_SIDEKICK_ID,
    diamond: 50,
    rarekey_count: 20,
    epickey_count: 0,
    skillbook_count: 0,
    shard_count: 10
  },
  {
    tier: 2,
    day: 2,
    sidekick_id: nil,
    diamond: 50,
    rarekey_count: 0,
    epickey_count: 10,
    skillbook_count: 0,
    shard_count: 10
  },
  {
    tier: 2,
    day: 3,
    sidekick_id: nil,
    diamond: 50,
    rarekey_count: 0,
    epickey_count: 0,
    skillbook_count: 30,
    shard_count: 10
  }
]

# Tier 3: $0.99
tier_3_rewards = [
  {
    tier: 3,
    day: 1,
    sidekick_id: ELEANOR_SIDEKICK_ID,
    diamond: 10,
    rarekey_count: 10,
    epickey_count: 0,
    skillbook_count: 0,
    shard_count: 10
  },
  {
    tier: 3,
    day: 2,
    sidekick_id: nil,
    diamond: 10,
    rarekey_count: 0,
    epickey_count: 5,
    skillbook_count: 0,
    shard_count: 10
  },
  {
    tier: 3,
    day: 3,
    sidekick_id: nil,
    diamond: 10,
    rarekey_count: 0,
    epickey_count: 0,
    skillbook_count: 10,
    shard_count: 10
  }
]

# Combine all rewards
all_rewards = tier_1_rewards + tier_2_rewards + tier_3_rewards

# Create or update each reward
all_rewards.each do |reward_data|
  reward = FirstChargeTierReward.find_or_initialize_by(
    tier: reward_data[:tier],
    day: reward_data[:day]
  )

  reward.assign_attributes(reward_data)

  if reward.save
    puts "  Created/Updated Tier #{reward.tier}, Day #{reward.day}: #{reward.diamond} diamonds"
  else
    puts "  ERROR creating Tier #{reward.tier}, Day #{reward.day}: #{reward.errors.full_messages.join(', ')}"
  end
end

puts "First Charge Tier Rewards seeding completed!"
puts "Total rewards configured: #{FirstChargeTierReward.count}"
