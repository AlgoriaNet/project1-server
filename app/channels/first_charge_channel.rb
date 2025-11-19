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

  # Claim first charge reward for a specific tier and day
  # Expected params: { tier: 1-3, day: 1-3 }
  def claim_reward(json)
    _json = JSON.parse(json['json'])
    tier = _json['tier']
    day = _json['day']

    begin
      # ========== Step 1: Validate Request Parameters ==========

      # Validate tier (1-3)
      unless tier.present? && [1, 2, 3].include?(tier)
        render_error "claim_reward", json, "Invalid tier. Must be 1, 2, or 3", 400
        return
      end

      # Validate day (1-3)
      unless day.present? && [1, 2, 3].include?(day)
        render_error "claim_reward", json, "Invalid day. Must be 1, 2, or 3", 400
        return
      end

      # Validate player exists
      unless player.present?
        render_error "claim_reward", json, "Player not found", 401
        return
      end

      # ========== Step 2: Check Purchase History ==========

      # Define first charge product IDs for each tier
      first_charge_products = {
        1 => "first_charge_tier1",
        2 => "first_charge_tier2",
        3 => "first_charge_tier3"
      }

      product_id = first_charge_products[tier]

      # Check if player has made a purchase for this tier (order status = 'paid' or 'delivered')
      purchase = Order.where(
        player_id: player.id,
        product_id: product_id,
        status: ['paid', 'delivered']
      ).first

      unless purchase.present?
        render_error "claim_reward", json, "Player has not purchased tier #{tier} first charge pack", 403
        return
      end

      # ========== Step 3: Validate Day Claimability ==========

      # Calculate when each day becomes claimable
      purchase_date = purchase.pay_time || purchase.created_at

      claimable_date = case day
      when 1
        purchase_date # Immediate
      when 2
        purchase_date.beginning_of_day + 1.day # Next calendar day
      when 3
        purchase_date.beginning_of_day + 2.days # 2 days later
      end

      current_time = Time.current

      if current_time < claimable_date
        time_until_claimable = ((claimable_date - current_time) / 3600.0).ceil # Hours until claimable
        render_error "claim_reward", json, "Day #{day} reward not yet claimable. Available in #{time_until_claimable} hours", 403
        return
      end

      # ========== Step 4: Check if Already Claimed ==========

      if FirstChargeClaim.claimed?(player.id, tier, day)
        render_error "claim_reward", json, "Tier #{tier} Day #{day} reward already claimed", 403
        return
      end

      # ========== Step 5: Get Reward Configuration ==========

      reward_config = FirstChargeTierReward.for_tier_and_day(tier, day).first

      unless reward_config.present?
        render_error "claim_reward", json, "Reward configuration not found for tier #{tier}, day #{day}", 500
        return
      end

      # Extract reward amounts
      diamond_amount = reward_config.diamond || 0
      rarekey_amount = reward_config.rarekey_count || 0
      epickey_amount = reward_config.epickey_count || 0
      skillbook_amount = reward_config.skillbook_count || 0
      shard_count = reward_config.shard_count || 10

      # ========== Step 6: Check Eleanor Sidekick Ownership (Day 1 only) ==========

      # Eleanor has base_id = 19 (per migration comment)
      eleanor_base_id = 19
      sidekick_reward = nil
      shard_reward = nil

      if day == 1
        # Check if player already owns Eleanor
        existing_sidekick = player.sidekicks.find_by(base_id: eleanor_base_id)

        if existing_sidekick.present?
          # Player owns Eleanor → give shards instead
          shard_reward = {
            item_name: "19_Eleanor",
            count: shard_count
          }
          Rails.logger.info "[FirstCharge] Player #{player.id} already owns Eleanor, granting #{shard_count} shards"
        else
          # Player doesn't own Eleanor → grant the sidekick
          sidekick_reward = {
            base_id: eleanor_base_id,
            skill_level: 1,
            star: 0
          }
          Rails.logger.info "[FirstCharge] Player #{player.id} does not own Eleanor, granting sidekick"
        end
      end

      # ========== Step 7: Deliver Rewards (Transaction) ==========

      delivered_items = {}

      ApplicationRecord.transaction do
        # Add diamonds
        if diamond_amount > 0
          player.diamond ||= 0
          player.diamond += diamond_amount
          delivered_items[:diamond] = diamond_amount
        end

        # Add rare keys (Day 1)
        if rarekey_amount > 0
          player.add_item("RareKey", rarekey_amount)
          delivered_items[:rare_keys] = rarekey_amount
        end

        # Add epic keys (Day 2)
        if epickey_amount > 0
          player.add_item("EpicKey", epickey_amount)
          delivered_items[:epic_keys] = epickey_amount
        end

        # Add skillbooks (Day 3 - Eleanor skillbook: SKb_19_Eleanor)
        if skillbook_amount > 0
          player.add_item("SKb_19_Eleanor", skillbook_amount)
          delivered_items[:skillbooks] = skillbook_amount
        end

        # Grant Eleanor sidekick OR shards (Day 1 only)
        if sidekick_reward.present?
          new_sidekick = Sidekick.create!(
            base_id: sidekick_reward[:base_id],
            player_id: player.id,
            skill_level: sidekick_reward[:skill_level],
            star: sidekick_reward[:star],
            is_deployed: false
          )
          delivered_items[:sidekick] = {
            id: new_sidekick.id,
            base_id: new_sidekick.base_id,
            name: "Eleanor"
          }
        elsif shard_reward.present?
          player.add_item(shard_reward[:item_name], shard_reward[:count])
          delivered_items[:shards] = {
            item_name: shard_reward[:item_name],
            count: shard_reward[:count]
          }
        end

        # Save player changes
        player.save!

        # ========== Step 8: Record the Claim ==========

        FirstChargeClaim.create!(
          player_id: player.id,
          tier: tier,
          day: day
          # claimed_at will be auto-set by model callback
        )

        Rails.logger.info "[FirstCharge] Successfully claimed tier #{tier} day #{day} for player #{player.id}"
      end

      # ========== Step 9: Return Success Response ==========

      # Reload player to get fresh data
      player.reload

      render_response "claim_reward", json, {
        success: true,
        tier: tier,
        day: day,
        rewards: delivered_items,
        player: player.as_ws_json
      }

    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error "[FirstCharge] Claim validation error: #{e.message}\n#{e.backtrace.join("\n")}"
      render_error "claim_reward", json, "Failed to claim reward: #{e.message}", 400
    rescue StandardError => e
      Rails.logger.error "[FirstCharge] Claim error: #{e.message}\n#{e.backtrace.join("\n")}"
      render_error "claim_reward", json, "Internal server error", 500
    end
  end
end
