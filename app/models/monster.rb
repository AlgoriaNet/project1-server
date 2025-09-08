class Monster < ApplicationRecord
  # Monster stats and behavior configuration
  validates :name, presence: true, uniqueness: true
  validates :level, presence: true, numericality: { greater_than: 0 }
  validates :hp, presence: true, numericality: { greater_than: 0 }
  validates :atk, presence: true, numericality: { greater_than: 0 }
  
  def as_battle_json
    {
      id: id,
      name: name,
      level: level,
      hp: hp,
      atk: atk,
      speed: speed || 1.0,
      abilities: abilities || [],
      rewards: rewards || {}
    }
  end
  
  # Get monsters appropriate for player level
  def self.for_player_level(player_level)
    # Return monsters within ±1 level of player
    level_range = [(player_level - 1), 1].max..(player_level + 1)
    where(level: level_range)
  end
  
  # Get monsters available for a specific stage level (1-100)
  def self.for_stage_level(stage_level)
    # Return monsters that can appear at this stage level based on habitat_levels
    where("JSON_CONTAINS(habitat_levels, ?)", stage_level.to_s)
  end
end
