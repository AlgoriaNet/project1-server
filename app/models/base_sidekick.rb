class BaseSidekick < ApplicationRecord
  belongs_to :base_skill, foreign_key: 'skill_id', class_name: 'BaseSkill'

  # 验证
  validates :name, presence: true, length: { maximum: 255 }
  validates :skill_id, presence: true

  def as_ws_json
    super(except: %w[variety_damage character skill_id description]).merge({
      'Id' => id,  # Add numeric ID for frontend animation mapping
      'Name' => name,
      'Skill' => {
        'Name' => base_skill.name,
        'Cd' => base_skill.cd,
        'Duration' => base_skill.duration,
        'Speed' => base_skill.speed,
        'SkillTargetType' => base_skill.skill_target_type
      }
    })
  end
end
