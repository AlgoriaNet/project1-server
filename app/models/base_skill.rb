class BaseSkill < ApplicationRecord
  has_many :level_up_effects, class_name: 'BaseSkillLevelUpEffect', foreign_key: 'skill_id'
  serialize :active_character, JSON
  def as_ws_json
    json = as_json
    json.delete("created_at")
    json.delete("updated_at")

    {}.tap do |h|
      json.each { |k, v| h[snake_to_camel(k)] = v }
    end
  end
end
