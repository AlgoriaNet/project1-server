class BaseSkillLevelUpEffect < ApplicationRecord
  belongs_to :base_skill, foreign_key: 'skill_id', class_name: 'BaseSkill'
  serialize :effects, JSON


  def as_ws_json
    json = as_json
    json.delete("created_at")
    json.delete("updated_at")
    json.delete("skill_id")
    json["skill_name"] = base_skill.name
    
    # Parse Effects JSON string back to hash for Unity compatibility
    if json["effects"].is_a?(String)
      json["effects"] = JSON.parse(json["effects"]) rescue json["effects"]
    end
    
    {}.tap do |h|
      json.each { |k, v| h[snake_to_camel(k)] = v }
    end
  end
end

