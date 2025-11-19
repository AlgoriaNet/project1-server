# frozen_string_literal: true

class MembershipCardChannel < ApplicationCable::Channel
  def stream_name
    "membership_card_channel_#{params[:user_id]}"
  end

  # Get all membership card reward configurations
  # Returns hash with 'weekly' and 'monthly' keys, each containing reward values
  def get_reward_config(json)
    _json = JSON.parse(json['json'])

    begin
      # Fetch all MembershipCardReward records and format for frontend
      all_rewards = MembershipCardReward.all_for_frontend

      render_response "get_reward_config", json, {
        success: true,
        rewards: all_rewards
      }
    rescue StandardError => e
      Rails.logger.error "[MembershipCard] Error fetching reward config: #{e.message}\n#{e.backtrace.join("\n")}"
      render_error "get_reward_config", json, "Failed to fetch reward configuration", 500
    end
  end
end
