# frozen_string_literal: true

require 'csv'

class BattleChannel < ApplicationCable::Channel

  def battle(json)
    begin
      # CRITICAL: Reload player to ensure fresh data from deployment updates
      player.reload
      # Check if player has enough stamina (10 stamina per battle)
      stamina_cost = 10
      current_stamina = player.stamina || 0
      
      if current_stamina < stamina_cost
        render_error "battle", json, "Not enough stamina. Need #{stamina_cost}, have #{current_stamina}", 400
        return
      end
      
      # Consume stamina before battle
      player.stamina -= stamina_cost
      player.save!
      
      # Return battle result with updated stamina
      battle_data = build_battle_data
      battle_data[:player] = {
        id: player.id,
        stamina: player.stamina
      }
      battle_data[:stamina_consumed] = stamina_cost
      
      render_response "battle", json, battle_data
    rescue StandardError => e
      Rails.logger.error "Battle error: #{e.message}\n#{e.backtrace.join("\n")}"
      render_error "battle", json, "Battle failed: #{e.message}", 500
    end
  end

  # Battle completion API - simple A+B approach
  def battle_complete(json)
    begin
      _json = JSON.parse(json['json'])  # Parse nested JSON like other channels
      victory = _json['victory'] # true for victory, false for defeat
      battle_data = _json['battle_data'] || {}
      
      # Determine base rewards based on battle result
      base_rewards = victory ? VICTORY_BASE_REWARDS : DEFEAT_BASE_REWARDS
      
      # Generate complete rewards
      rewards = calculate_battle_rewards(base_rewards)
      
      # Apply rewards to player (save immediately)
      ApplicationRecord.transaction do
        apply_rewards_to_player(rewards)

        # Handle stage progression on victory
        if victory && _json['current_stage']
          completed_stage = _json['current_stage'].to_i
          current_max = player.max_unlocked_stage || 1

          # Unlock next stage if player completed their current max stage or higher
          if completed_stage >= current_max
            player.max_unlocked_stage = completed_stage + 1
            Rails.logger.info "Player #{player.id} completed stage #{completed_stage}, unlocked stage #{completed_stage + 1}"
          end
        end

        # Save all changes (rewards + stage progression)
        player.save!
      end
      
      # Return complete battle result with rewards
      render_response "battle_complete", json, {
        victory: victory,
        rewards: format_rewards_for_frontend(rewards),
        updated_player: player.reload.as_ws_json
      }
      
    rescue StandardError => e
      Rails.logger.error "Battle complete error: #{e.message}\n#{e.backtrace.join("\n")}"
      render_error "battle_complete", json, "Battle completion failed: #{e.message}", 500
    end
  end

  # Battle configuration API - Updated September 2025 with CSV-based system
  # STAGE-LEVEL BASED: Uses stage_level (1-100) + sub_level (1-20) format only
  def get_battle_config(json)
    begin
      _json = JSON.parse(json['json'])
      
      # REQUIRED: stage_level + sub_level parameters
      stage_level = _json['stage_level']
      sub_level = _json['sub_level'] || 10 # Default to mid-stage if not provided
      battle_type = _json['battle_type'] || 'normal'
      
      # Validate required parameters
      unless stage_level.present?
        render_error "get_battle_config", json, "Missing required parameter: stage_level", 400
        return
      end
      
      # Validate ranges
      stage_level = stage_level.to_i
      sub_level = sub_level.to_i
      
      if stage_level < 1 || stage_level > 100
        render_error "get_battle_config", json, "Invalid stage_level: #{stage_level}. Must be 1-100", 400
        return
      end
      
      if sub_level < 1 || sub_level > 20
        render_error "get_battle_config", json, "Invalid sub_level: #{sub_level}. Must be 1-20", 400
        return
      end
      
      Rails.logger.info "Generating battle configuration for stage #{stage_level}.#{sub_level} (#{battle_type})"
      battle_config = generate_csv_battle_config(stage_level, sub_level, battle_type)
      
      Rails.logger.info "Battle config generated successfully, sending response..."
      render_response "get_battle_config", json, battle_config
      Rails.logger.info "Response sent to frontend"
      
    rescue StandardError => e
      Rails.logger.error "Get battle config error: #{e.message}\n#{e.backtrace.join("\n")}"
      render_error "get_battle_config", json, "Failed to generate battle config: #{e.message}", 500
    end
  end

  def build_battle_data
    # CRITICAL: Reload player to ensure fresh deployment data from other channel updates
    player.reload
    # Get player's deployed sidekicks from lineup
    deployed_sidekicks = player.sidekicks.where(is_deployed: true).includes(:base_sidekick)
    base_sidekicks = deployed_sidekicks.map(&:base_sidekick)
    
    # Frontend now uses StaticSkillEffectsCache instead of levelUpEffects
    # Removed complex random selection logic per frontend notification (2025-09-05)
    
    {
      main_stage: {},
      sidekicks: base_sidekicks.map(&:as_ws_json)
      # levelUpEffects removed - frontend uses StaticSkillEffectsCache
    }
  end

  private

  # Generate balanced battle waves (replaces hardcoded 20,000 monsters!)
  def generate_battle_waves(available_monsters, player_level, battle_type)
    case battle_type
    when 'normal'
      # Easy battle: 3 waves, 2-3 monsters per wave, winnable in 2-3 minutes
      waves = []
      
      # Wave 1: 2 weak monsters
      wave1_monsters = available_monsters.sample(2)
      waves << {
        wave: 1,
        monsters: wave1_monsters.map { |m| { 
          name: m.name, 
          count: 1, 
          hp: m.hp, 
          atk: m.atk,
          spawn_delay: 2.0  # 2 seconds between spawns
        }},
        total_monsters: 2
      }
      
      # Wave 2: 3 mixed monsters  
      wave2_monsters = available_monsters.sample(2) # 2 types
      waves << {
        wave: 2, 
        monsters: wave2_monsters.map { |m| {
          name: m.name,
          count: m.name == 'Goblin' ? 2 : 1,  # More goblins since they're weak
          hp: m.hp,
          atk: m.atk,
          spawn_delay: 1.5
        }},
        total_monsters: 3
      }
      
      # Wave 3: Final wave - slightly tougher
      wave3_monsters = available_monsters.where(level: [player_level, player_level + 1].max)
      if wave3_monsters.empty?
        wave3_monsters = available_monsters
      end
      
      waves << {
        wave: 3,
        monsters: wave3_monsters.sample(1).map { |m| {
          name: m.name,
          count: 2,
          hp: (m.hp * 1.2).to_i,  # 20% more HP for final wave
          atk: m.atk,
          spawn_delay: 1.0
        }},
        total_monsters: 2  
      }
      
      {
        total_waves: 3,
        total_monsters: waves.sum { |w| w[:total_monsters] }, # 7 total monsters
        waves: waves,
        difficulty: 'normal',
        estimated_time: '2-3 minutes'
      }
      
    when 'boss'
      # Boss battle: 1 tough monster + minions
      {
        total_waves: 1,
        total_monsters: 3,
        waves: [{
          wave: 1,
          monsters: [{
            name: 'Boss_Orc',
            count: 1,  
            hp: 150,
            atk: 20,
            spawn_delay: 0
          }, {
            name: 'Goblin',
            count: 2,
            hp: 30,
            atk: 8, 
            spawn_delay: 1.0
          }],
          total_monsters: 3
        }],
        difficulty: 'boss',
        estimated_time: '3-5 minutes'
      }
      
    else
      # Default to normal battle
      generate_battle_waves(available_monsters, player_level, 'normal')
    end
  end

  # Battle reward constants
  VICTORY_BASE_REWARDS = {
    exp: 20,
    gold_coin: 150,
    gunScroll: 2,
    equipScroll: 2,
    random_sidekick_skillbooks: 2,
    random_equipment: 1,
    random_gemstone: 1
  }.freeze

  DEFEAT_BASE_REWARDS = {
    exp: 10,
    gold_coin: 75,
    gunScroll: 1,
    equipScroll: 1,
    random_sidekick_skillbooks: 1,
    random_equipment: 0,
    random_gemstone: 0
  }.freeze

  # Equipment rarity distribution (Quality 1-6)
  EQUIPMENT_DROP_RATES = {
    1 => 45, # Common - 45%
    2 => 25, # Uncommon - 25%  
    3 => 15, # Rare - 15%
    4 => 10, # Epic - 10%
    5 => 4,  # Legendary - 4%
    6 => 1   # Mythic - 1%
  }.freeze

  # Gemstone rarity distribution (Level 1-7)
  GEMSTONE_DROP_RATES = {
    1 => 40, # Common - 40%
    2 => 25, # Uncommon - 25%
    3 => 15, # Rare - 15% 
    4 => 10, # Epic - 10%
    5 => 6,  # Legendary - 6%
    6 => 3,  # Mythic - 3%
    7 => 1   # Divine - 1%
  }.freeze

  def calculate_battle_rewards(base_rewards)
    {
      fixed: {
        exp: base_rewards[:exp],
        gold_coin: base_rewards[:gold_coin],
        gunScroll: base_rewards[:gunScroll],
        equipScroll: base_rewards[:equipScroll]
      },
      skillbooks: generate_sidekick_skillbooks(base_rewards[:random_sidekick_skillbooks]),
      equipment: generate_equipment_rewards(base_rewards[:random_equipment]),
      gemstones: generate_gemstone_rewards(base_rewards[:random_gemstone])
    }
  end

  def generate_sidekick_skillbooks(count)
    return [] if count == 0
    
    # Get only sidekick skillbooks (exclude equipScroll)
    sidekick_skillbooks = BaseItem.where("name LIKE ?", "SKb_%")
                                 .where.not(name: "equipScroll")
                                 .pluck(:name)
    
    skillbooks = []
    count.times do
      skillbooks << sidekick_skillbooks.sample
    end
    
    # Group duplicates: [A, A, B] → [{name: A, quantity: 2}, {name: B, quantity: 1}]
    skillbooks.tally.map { |name, qty| { name: name, quantity: qty } }
  end

  def generate_equipment_rewards(count)
    return [] if count == 0
    
    equipment_list = []
    available_equipment = BaseEquipment.all
    
    count.times do
      # Select equipment quality based on rarity rates
      quality = select_by_rarity(EQUIPMENT_DROP_RATES)
      
      # Get equipment of selected quality
      base_equipment = available_equipment.select { |eq| eq.name.match(/#{quality.to_s.rjust(2, '0')}$/) }.sample
      base_equipment ||= available_equipment.sample # Fallback to any equipment
      
      # Create equipment with level 1, rank 1, and random attributes
      equipment = Equipment.create!(
        player: player,
        base_equipment: base_equipment,
        intensify_level: 1,
        upgrade_rank: 1
      )
      
      # Generate random attributes via washing
      equipment.washing
      equipment.save!
      
      equipment_list << equipment
    end
    
    equipment_list
  end

  def generate_gemstone_rewards(count)
    return [] if count == 0
    
    gemstone_list = []
    
    count.times do
      # Select gemstone level based on rarity rates
      level = select_by_rarity(GEMSTONE_DROP_RATES)
      
      # Generate gemstone with random part and attributes
      gemstone = Gemstone.generate(level, player.id)
      gemstone.is_in_inventory = true
      gemstone.save!
      
      gemstone_list << gemstone
    end
    
    gemstone_list
  end

  def select_by_rarity(rates_hash)
    total = rates_hash.values.sum
    random_value = rand(1..total)
    
    cumulative = 0
    rates_hash.each do |quality, rate|
      cumulative += rate
      return quality if random_value <= cumulative
    end
    
    rates_hash.keys.first # Fallback
  end

  def apply_rewards_to_player(rewards)
    # Apply fixed rewards
    player.exp += rewards[:fixed][:exp]
    player.gold_coin += rewards[:fixed][:gold_coin]
    
    # Apply scroll rewards
    player.add_item!("gunScroll", rewards[:fixed][:gunScroll])
    player.add_item!("equipScroll", rewards[:fixed][:equipScroll])
    
    # Apply skillbook rewards
    rewards[:skillbooks].each do |skillbook|
      player.add_item!(skillbook[:name], skillbook[:quantity])
    end
    
    # Equipment and gemstones are already created and assigned to player
    
    player.save!
    
    # Check for level up after EXP gain
    LevelService.get_level_info(player)
  end

  def format_rewards_for_frontend(rewards)
    {
      fixed: rewards[:fixed],
      skillbooks: rewards[:skillbooks],
      equipment: rewards[:equipment].map(&:as_ws_json),
      gemstones: rewards[:gemstones].map(&:as_ws_json)
    }
  end

  # NEW: CSV-based monster configuration system (September 2025)
  # CAUTIOUS IMPLEMENTATION: Adds new functionality without breaking existing system

  private

  def load_stage_monsters_csv
    @stage_monsters_cache ||= begin
      csv_path = Rails.root.join('lib', 'config', 'stage_monsters.csv')
      return {} unless File.exist?(csv_path)
      
      monsters_by_stage = {}
      CSV.foreach(csv_path, headers: true) do |row|
        # Skip comment lines
        next if row['stage_level'].nil? || row['stage_level'].start_with?('#')
        
        stage_level = row['stage_level'].to_i
        sub_level_range = row['sub_level_range']
        
        monsters_by_stage[stage_level] ||= {}
        monsters_by_stage[stage_level][sub_level_range] ||= []
        
        monsters_by_stage[stage_level][sub_level_range] << {
          name: row['monster_name'],
          spawn_chance: row['spawn_chance'].to_i,
          base_count: row['base_count'].to_i,
          spawn_interval: row['spawn_interval'].to_f,
          hp: row['hp'].to_i,
          atk: row['atk'].to_i,
          speed: row['speed'].to_f,
          exp_reward: row['exp_reward'].to_i
        }
      end
      monsters_by_stage
    rescue => e
      Rails.logger.error "Failed to load stage_monsters.csv: #{e.message}"
      {}
    end
  end

  def load_battle_level_progression_csv
    @battle_progression_cache ||= begin
      csv_path = Rails.root.join('lib', 'config', 'battle_level_progression.csv')
      return {} unless File.exist?(csv_path)
      
      progression = {}
      CSV.foreach(csv_path, headers: true) do |row|
        battle_level = row['battle_level'].to_i
        exp_required = row['exp_required'] == 'MAX' ? 'MAX' : row['exp_required'].to_i
        progression[battle_level] = exp_required
      end
      progression
    rescue => e
      Rails.logger.error "Failed to load battle_level_progression.csv: #{e.message}"
      # Fallback to original system
      (1..20).each_with_object({}) { |level, hash| hash[level] = level < 20 ? 100 : 'MAX' }
    end
  end

  def get_sub_level_range(sub_level)
    case sub_level
    when 1..5 then '1-5'
    when 6..10 then '6-10'  
    when 11..15 then '11-15'
    when 16..20 then '16-20'
    else '1-20' # Fallback for stages that use full range
    end
  end

  def load_monsters_for_stage(stage_level, sub_level)
    stage_monsters = load_stage_monsters_csv
    return [] unless stage_monsters[stage_level]
    
    # Try specific sub-level range first
    sub_range = get_sub_level_range(sub_level)
    monsters = stage_monsters[stage_level][sub_range]
    
    # Fallback to full range if specific range not found
    monsters ||= stage_monsters[stage_level]['1-20']
    
    monsters || []
  end

  # CSV-based battle configuration generation (September 2025)
  def generate_csv_battle_config(stage_level, sub_level, battle_type)
    monsters = load_monsters_for_stage(stage_level, sub_level)
    battle_progression = load_battle_level_progression_csv
    
    # Fallback strategy for missing stage data
    if monsters.empty?
      Rails.logger.warn "No monsters found for stage #{stage_level}.#{sub_level}, falling back to stage 1"
      monsters = load_monsters_for_stage(1, sub_level)
      
      if monsters.empty?
        Rails.logger.error "Critical error: No fallback monsters available"
        raise "Monster configuration unavailable for stage #{stage_level}.#{sub_level}"
      end
    end
    
    Rails.logger.info "Loaded #{monsters.size} monster types for stage #{stage_level}.#{sub_level}"
    
    {
      battle_config: {
        stage_level: stage_level,
        sub_level: sub_level,
        battle_type: battle_type,
        monsters: monsters,
        total_monster_types: monsters.size,
        estimated_duration: estimate_battle_duration(monsters)
      },
      battle_level_progression: battle_progression
    }
  end

# REMOVED: Legacy battle configuration generation
  # generate_legacy_battle_config method removed - no longer needed
  # Monster.for_player_level and generate_battle_waves methods kept for safety

  def estimate_battle_duration(monsters)
    return "2-3 minutes" if monsters.empty?
    
    begin
      avg_spawn_interval = monsters.map { |m| m[:spawn_interval] }.sum / monsters.size
      total_monsters = monsters.map { |m| m[:base_count] }.sum
      
      estimated_seconds = (total_monsters * avg_spawn_interval * 1.5).round # 1.5x buffer for combat
      minutes = estimated_seconds / 60
      seconds = estimated_seconds % 60
      "#{minutes}:#{seconds.to_s.rjust(2, '0')} minutes"
    rescue => e
      Rails.logger.error "Error estimating battle duration: #{e.message}"
      "2-3 minutes"
    end
  end


end
