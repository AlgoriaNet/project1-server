# frozen_string_literal: true

class BattleChannel < ApplicationCable::Channel
  def subscribed
    stream_from "Battle_#{params[:user_id]}"
    Rails.logger.info("subscribed to gaming")
    Rails.logger.info(params)
  end

  def battle(json)
    Rails.logger.info("battle #{json}")
    ActionCable.server.broadcast("Battle_1", { action: "battle", code: 200, requestId: json["requestId"], data: mock_result })
  end

  def mock_result()
    sidekicks = BaseSidekick.where("id in (1)")
    levelUpEffects = sidekicks.map{|s| s.base_skill.level_up_effects }.flatten
    {
      main_stage: {},
      sidekicks: sidekicks.map(&:as_ws_json),
      levelUpEffects: levelUpEffects.map(&:as_ws_json)
    }
  end
end
