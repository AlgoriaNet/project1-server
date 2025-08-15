# frozen_string_literal: true

class BattleChannel < ApplicationCable::Channel

  def battle(json)
    begin
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
      battle_data = mock_result
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

  def mock_result
    sidekicks = BaseSidekick.where("id in (1)")
    levelUpEffects = sidekicks.map{|s| s.base_skill.level_up_effects }.flatten
    {
      main_stage: {},
      sidekicks: sidekicks.map(&:as_ws_json),
      levelUpEffects: levelUpEffects.map(&:as_ws_json)
    }
  end

  private

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
end
