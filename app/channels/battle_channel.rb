# frozen_string_literal: true

class BattleChannel < ApplicationCable::Channel

  def battle(json)
    begin
      # Check if player has enough stamina (10 stamina per battle)
      stamina_cost = 10
      current_stamina = player.stamina || 0
      
      if current_stamina < stamina_cost
        render_error "battle", json, "Not enough stamina. Need #{stamina_cost}, have #{current_stamina}", 400
        return
      end
      
      # Consume stamina before battle
      player.stamina -= stamina_cost
      player.save!
      
      # Return battle result with updated stamina
      battle_data = mock_result
      battle_data[:player] = {
        id: player.id,
        stamina: player.stamina
      }
      battle_data[:stamina_consumed] = stamina_cost
      
      render_response "battle", json, battle_data
    rescue StandardError => e
      Rails.logger.error "Battle error: #{e.message}\n#{e.backtrace.join("\n")}"
      render_error "battle", json, "Battle failed: #{e.message}", 500
    end
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
