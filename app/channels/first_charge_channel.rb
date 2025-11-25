# frozen_string_literal: true

class FirstChargeChannel < ApplicationCable::Channel
  def stream_name
    "first_charge_channel_#{params[:user_id]}"
  end

  # Get all reward configurations for all tiers and days
  # Returns array of 9 reward records (3 tiers × 3 days)
  def get_reward_config(json)
    _json = JSON.parse(json['json'])

    begin
      # Fetch all FirstChargeTierReward records
      all_rewards = FirstChargeTierReward.all.map do |reward|
        {
          tier: reward.tier,
          day: reward.day,
          diamond: reward.diamond,
          rarekey_count: reward.rarekey_count,
          epickey_count: reward.epickey_count,
          skillbook_count: reward.skillbook_count,
          shard_count: reward.shard_count
        }
      end

      render_response "get_reward_config", json, {
        success: true,
        rewards: all_rewards
      }
    rescue StandardError => e
      Rails.logger.error "[FirstCharge] Error fetching reward config: #{e.message}\n#{e.backtrace.join("\n")}"
      render_error "get_reward_config", json, "Failed to fetch reward configuration", 500
    end
  end

  # Get purchase status for all tiers for the current player
  # Checks FirstChargeClaim table - if a tier has any claim, it means it was purchased
  # Returns: { tier1_purchased: true/false, tier2_purchased: true/false, tier3_purchased: true/false }
  def get_purchase_status(json)
    _json = JSON.parse(json['json'])

    begin
      # Check if player has any FirstChargeClaim for each tier
      # This distinguishes FirstCharge purchases from regular diamond purchases
      tier1_purchased = FirstChargeClaim.exists?(player_id: player.id, tier: 1)
      tier2_purchased = FirstChargeClaim.exists?(player_id: player.id, tier: 2)
      tier3_purchased = FirstChargeClaim.exists?(player_id: player.id, tier: 3)

      render_response "get_purchase_status", json, {
        success: true,
        tier1_purchased: tier1_purchased,
        tier2_purchased: tier2_purchased,
        tier3_purchased: tier3_purchased
      }
    rescue StandardError => e
      Rails.logger.error "[FirstCharge] Error fetching purchase status: #{e.message}\n#{e.backtrace.join("\n")}"
      render_error "get_purchase_status", json, "Failed to fetch purchase status", 500
    end
  end

  # Get all claims for the current player
  # Returns array of claimed tier/day combinations
  def get_claim_status(json)
    _json = JSON.parse(json['json'])

    begin
      # Fetch all FirstChargeClaim records for this player
      claims = FirstChargeClaim.where(player_id: player.id).map do |claim|
        {
          tier: claim.tier,
          day: claim.day,
          claimed_at: claim.claimed_at
        }
      end

      render_response "get_claim_status", json, {
        success: true,
        claims: claims
      }
    rescue StandardError => e
      Rails.logger.error "[FirstCharge] Error fetching claim status: #{e.message}\n#{e.backtrace.join("\n")}"
      render_error "get_claim_status", json, "Failed to fetch claim status", 500
    end
  end

  # Claim first charge reward for a specific tier and day
  # Fetches reward config from database and gives rewards
  def claim_reward(json)
    _json = JSON.parse(json['json'])
    tier = _json['tier']
    day = _json['day']

    begin
      # Fetch reward config from database
      reward_config = FirstChargeTierReward.find_by(tier: tier, day: day)
      return render_error "claim_reward", json, "Invalid tier/day configuration", 400 unless reward_config

      # Just give the rewards
      ApplicationRecord.transaction do
        # Check if already claimed (INSIDE transaction to prevent race condition)
        if FirstChargeClaim.exists?(player_id: player.id, tier: tier, day: day)
          raise ArgumentError, "Reward already claimed for this tier and day"
        end

        # Add diamond
        player.diamond += reward_config.diamond if reward_config.diamond > 0

        # Add rarekey
        player.add_item("RareKey", reward_config.rarekey_count) if reward_config.rarekey_count > 0

        # Add epickey
        player.add_item("EpicKey", reward_config.epickey_count) if reward_config.epickey_count > 0

        # Add skillbook (Eleanor)
        player.add_item("SKb_19_Eleanor", reward_config.skillbook_count) if reward_config.skillbook_count > 0

        # Add shard (Eleanor)
        player.add_item("Shard_19_Eleanor", reward_config.shard_count) if reward_config.shard_count > 0

        # Record the claim
        FirstChargeClaim.create!(player_id: player.id, tier: tier, day: day)

        player.save!
      end

      render_response "claim_reward", json, {
        success: true,
        rewards: {
          diamond: reward_config.diamond,
          rare_keys: reward_config.rarekey_count,
          epic_keys: reward_config.epickey_count,
          skillbooks: reward_config.skillbook_count,
          shards: reward_config.shard_count
        },
        player: player.as_ws_json
      }

    rescue => e
      Rails.logger.error "[FirstCharge] Claim error: #{e.message}"
      render_error "claim_reward", json, "Failed to claim reward", 500
    end
  end
end
