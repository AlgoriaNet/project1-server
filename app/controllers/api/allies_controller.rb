class Api::AlliesController < ApplicationController
  def upgrade_levels
    ally_id = params[:ally_id]
    
    # Find sidekick by fragment_name (e.g., "02_Gideon")
    sidekick = BaseSidekick.find_by(fragment_name: ally_id)
    
    if sidekick.nil?
      render json: { error: "Ally not found" }, status: 404
      return
    end
    
    # Get upgrade levels for this specific sidekick
    upgrade_levels = BaseSkillLevelUpEffect.where(skill_id: sidekick.skill_id)
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
        is_unlocked: false  # This would need to be checked against player's current level
      }
    end
    
    render json: {
      ally_id: ally_id,
      name: sidekick.name,
      cn_name: sidekick.cn_name,
      current_level: 1,  # This would come from player's sidekick data
      upgrade_levels: upgrade_levels
    }
  end
end