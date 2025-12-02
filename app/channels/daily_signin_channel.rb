# frozen_string_literal: true

class DailySigninChannel < ApplicationCable::Channel
  def stream_name
    "daily_signin_channel_#{params[:user_id]}"
  end

  # Get all reward configurations for 30 days
  # Returns array of 30 reward records with details for each day
  def get_rewards_config(json)
    _json = JSON.parse(json['json'])

    begin
      # Fetch all DailySigninReward records (1-30 days)
      all_rewards = DailySigninReward.order(:day_number).map do |reward|
        {
          day_number: reward.day_number,
          reward_type: reward.reward_type,
          gold_coin: reward.gold_coin,
          skillbook_count: reward.skillbook_count,
          diamond: reward.diamond,
          epic_key: reward.epic_key,
          hero_key: reward.hero_key,
          rare_key: reward.rare_key
        }
      end

      render_response "get_rewards_config", json, {
        success: true,
        rewards: all_rewards
      }
    rescue StandardError => e
      Rails.logger.error "[DailySignin] Error fetching reward config: #{e.message}\n#{e.backtrace.join("\n")}"
      render_error "get_rewards_config", json, "Failed to fetch reward configuration", 500
    end
  end

  # Get player's current sign-in status
  # Returns cycle info, claimed days, milestones, consecutive days, etc.
  def get_signin_status(json)
    _json = JSON.parse(json['json'])

    begin
      status = player.signin_status

      render_response "get_signin_status", json, {
        success: true,
        status: status
      }
    rescue StandardError => e
      Rails.logger.error "[DailySignin] Error fetching sign-in status: #{e.message}\n#{e.backtrace.join("\n")}"
      render_error "get_signin_status", json, "Failed to fetch sign-in status", 500
    end
  end

  # Claim today's daily sign-in reward
  # Awards rewards and advances to next day in cycle
  def claim_daily_signin(json)
    _json = JSON.parse(json['json'])

    begin
      result = player.claim_daily_signin!

      render_response "claim_daily_signin", json, {
        success: true,
        day_claimed: result[:day_claimed],
        rewards: result[:rewards],
        player: player.as_ws_json
      }

    rescue ArgumentError => e
      Rails.logger.warn "[DailySignin] Claim validation failed: #{e.message}"
      render_error "claim_daily_signin", json, e.message, 400

    rescue StandardError => e
      Rails.logger.error "[DailySignin] Claim error: #{e.message}\n#{e.backtrace.join("\n")}"
      render_error "claim_daily_signin", json, "Failed to claim daily sign-in", 500
    end
  end

  # Reclaim a missed day by paying 20 diamonds
  # Allows player to fill in gaps in their sign-in calendar
  def reclaim_daily_signin(json)
    _json = JSON.parse(json['json'])
    day_number = _json['day_number']

    begin
      # Validate input
      return render_error "reclaim_daily_signin", json, "day_number is required", 400 unless day_number

      result = player.reclaim_daily_signin!(day_number)

      render_response "reclaim_daily_signin", json, {
        success: true,
        day_reclaimed: result[:day_reclaimed],
        rewards: result[:rewards],
        diamonds_spent: result[:diamonds_spent],
        player: player.as_ws_json
      }

    rescue ArgumentError => e
      Rails.logger.warn "[DailySignin] Reclaim validation failed: #{e.message}"
      render_error "reclaim_daily_signin", json, e.message, 400

    rescue StandardError => e
      Rails.logger.error "[DailySignin] Reclaim error: #{e.message}\n#{e.backtrace.join("\n")}"
      render_error "reclaim_daily_signin", json, "Failed to reclaim day", 500
    end
  end

  # Claim a milestone reward (days 7, 14, 21, 30)
  # Can be claimed once player has reached that many claimed days
  def claim_milestone(json)
    _json = JSON.parse(json['json'])
    milestone_day = _json['milestone_day']

    begin
      # Validate input
      return render_error "claim_milestone", json, "milestone_day is required", 400 unless milestone_day

      result = player.claim_milestone!(milestone_day)

      render_response "claim_milestone", json, {
        success: true,
        milestone_claimed: result[:milestone_claimed],
        rewards: result[:rewards],
        player: player.as_ws_json
      }

    rescue ArgumentError => e
      Rails.logger.warn "[DailySignin] Milestone claim validation failed: #{e.message}"
      render_error "claim_milestone", json, e.message, 400

    rescue StandardError => e
      Rails.logger.error "[DailySignin] Milestone claim error: #{e.message}\n#{e.backtrace.join("\n")}"
      render_error "claim_milestone", json, "Failed to claim milestone", 500
    end
  end
end
