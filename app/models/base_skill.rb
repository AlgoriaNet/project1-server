class BaseSkill < ApplicationRecord
  has_many :level_up_effects, class_name: 'BaseSkillLevelUpEffect', foreign_key: 'skill_id'
  serialize :active_character, JSON
end
