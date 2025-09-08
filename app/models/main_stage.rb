class MainStage < ApplicationRecord
  validates :stage_number, presence: true, numericality: { in: 1..100 }
  validates :level, presence: true, numericality: { in: 1..20 }
  
  # JSON fields (no serialize needed for JSON columns)
  
  # Stage display format: "1.1", "1.2", "20.5"
  def display_stage
    visual_group = ((stage_number - 1) / 5) + 1
    stage_in_group = ((stage_number - 1) % 5) + 1
    "#{visual_group}.#{stage_in_group}"
  end
  
  # Get difficulty coefficient based on level within stage
  def difficulty_coefficient
    case level
    when 1..5 then 1.0      # Easy start
    when 6..10 then 1.5     # Medium difficulty 
    when 11..15 then 2.0    # Hard
    when 16..20 then 3.0    # Very hard
    end
  end
  
  # Generate monster configuration using your format
  def generate_monsters_config
    # Get monsters available for this stage based on habitat_levels
    available_monsters = Monster.for_stage_level(stage_number)
    level_difficulty = difficulty_coefficient
    
    # Your format: [[monster_names], rounds, interval]
    config = []
    
    # Wave 1: Basic monsters
    basic_monsters = available_monsters.where(is_boss: false, is_elite: false)
    if basic_monsters.any?
      monster_names = basic_monsters.sample(2).pluck(:name)
      rounds = (20 * level_difficulty).to_i
      interval = 0.8 - (level_difficulty * 0.1) # Faster spawns at higher difficulty
      config << [monster_names, rounds, interval]
    end
    
    # Wave 2: Mixed with elites (levels 5, 10, 15, 20)
    if level % 5 == 0
      elite_monsters = available_monsters.where(is_elite: true)
      if elite_monsters.any?
        elite_names = elite_monsters.sample(1).pluck(:name)
        config << [elite_names, (5 * level_difficulty).to_i, 1.0]
      end
    end
    
    # Boss wave (level 20 only)  
    if level == 20
      boss_monsters = available_monsters.where(is_boss: true)
      if boss_monsters.any?
        boss_name = boss_monsters.sample(1).pluck(:name)
        config << [boss_name, 1, 2.0] # Single boss, slow spawn
      end
    end
    
    config
  end
  
  def as_battle_json
    {
      stage: display_stage,
      level: level,
      type: "main",
      coefficient: difficulty_coefficient,
      monsters: monsters_config || generate_monsters_config
    }
  end
  
  # Find or create stage configuration
  def self.get_stage_config(stage_number, level)
    stage = find_or_create_by(
      stage_number: stage_number, 
      level: level
    ) do |s|
      visual_group = ((stage_number - 1) / 5) + 1
      stage_in_group = ((stage_number - 1) % 5) + 1
      s.name = "Stage #{visual_group}.#{stage_in_group}"
    end
    
    # Generate config after stage is created and has all attributes
    if stage.monsters_config.nil?
      stage.monsters_config = stage.generate_monsters_config
      stage.save!
    end
    
    stage
  end
  
end
