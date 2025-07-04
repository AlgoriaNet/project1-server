class BaseSidekick < ApplicationRecord
  belongs_to :base_skill, foreign_key: 'skill_id', class_name: 'BaseSkill'

  # 验证
  validates :name, presence: true, length: { maximum: 255 }
  validates :skill_id, presence: true

  def as_ws_json
    super(except: %w[variety_damage character skill_id description])
  end
end
