# frozen_string_literal: true

class PeriodicReward
  def self.receive_reward(player_id)
    player = Player.find(player_id)
    today = Time.current.to_date.to_s
    weekly_receive_status = player.weekly_periodic_rewards_received_date.value == today
    monthly_receive_status = player.monthly_periodic_rewards_received_date.value == today

    if player.weekly_card_expiry.present? && player.weekly_card_expiry > today && !weekly_receive_status
      rewards = {
        "gold_coin" => 100,
        "items" => { "rareKey" => 1, "epicKey" => 1 }
      }
      ResourceService.new(player.id, rewards).add_resource
      player.weekly_periodic_rewards_received_date = today
      player.save!
      ActionCable.server.broadcast("player_channel_#{player.id}", { action: "send_periodic_rewards",
                                                                    code: 200,
                                                                    data: {
                                                                      type: "weekly",
                                                                      rewards: rewards,
                                                                      Player: player.as_ws_json
                                                                    }})
    end

    if player.monthly_card_expiry.present? && player.monthly_card_expiry > today && !monthly_receive_status
      rewards = {
        "diamond" => 80,
        "stamina" => 100,
        "gold_coin" => 200,
      }
      ResourceService.new(player.id, rewards).add_resource
      player.monthly_periodic_rewards_received_date = today
      player.save!
      ActionCable.server.broadcast("player_channel_#{player.id}", { action: "send_periodic_rewards",
                                                                    code: 200,
                                                                    data: {
                                                                      type: "monthly",
                                                                      rewards: rewards,
                                                                      Player: player.as_ws_json
                                                                    } })
    end
  end
end
