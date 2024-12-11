class BaseSidekick < ApplicationRecord
  belongs_to :base_skill, foreign_key: 'skill_id', class_name: 'BaseSkill'

  # 验证
  validates :name, presence: true, length: { maximum: 255 }
  validates :skill_id, presence: true

  def as_ws_json
    json = as_json
    json.delete("created_at")
    json.delete("updated_at")
    json.delete("variety_damage")
    json.delete("character")
    json.delete("skill_id")
    json.delete("description")

    {}.tap do |h|
      json.each { |k, v| h[snake_to_camel(k)] = v }
      h["Skill"] = base_skill.as_ws_json
    end
  end
end


