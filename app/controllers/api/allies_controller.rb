class Api::AlliesController < ApplicationController
  def upgrade_levels
    ally_id = params[:ally_id]
    sidekick = BaseSidekick.find_by(fragment_name: ally_id)
    if sidekick.nil?
      render json: { error: "Ally not found" }, status: 404
      return
    end
    upgrade_levels = self.class.upgrade_levels_for_ally(sidekick, ally_id)
    render json: {
      ally_id: ally_id,
      name: sidekick.name,
      cn_name: sidekick.cn_name,
      current_level: 1,  # This would come from player's sidekick data
      upgrade_levels: upgrade_levels
    }
  end

  def level_up_costs
    # Load universal level up costs from CSV
    costs = CsvConfig.load_level_up_costs
    
    # Format for API response
    cost_data = costs.map do |cost|
      {
        level: cost[:level],
        skillbook_cost: cost[:skillbook_cost],
        gold_cost: cost[:gold_cost]
      }
    end
    
    render json: {
      level_up_costs: cost_data
    }
  end

  # Shared logic for both REST and WebSocket
  def self.upgrade_levels_for_ally(sidekick, ally_id, current_level = 1)
    BaseSkillLevelUpEffect.where(skill_id: sidekick.skill_id)
      .select { |upgrade| 
        effects = JSON.parse(upgrade.effects || '{}')
        effects['sidekick_fragment_name'] == ally_id
      }
      .sort_by(&:level)
      .map do |upgrade|
        {
          level: "L#{upgrade.level.to_s.rjust(2, '0')}",
          description: upgrade.description,
          cost: upgrade.weight,
          is_unlocked: current_level >= upgrade.level
        }
      end
  end
end