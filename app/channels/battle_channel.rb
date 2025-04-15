# frozen_string_literal: true

class BattleChannel < ApplicationCable::Channel

  def battle(json)
    render_response "battle", json, mock_result
  end

  def mock_result
    sidekicks = BaseSidekick.where("id in (1)")
    levelUpEffects = sidekicks.map{|s| s.base_skill.level_up_effects }.flatten
    {
      main_stage: {},
      sidekicks: sidekicks.map(&:as_ws_json),
      levelUpEffects: levelUpEffects.map(&:as_ws_json)
    }
  end
end
