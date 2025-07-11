# frozen_string_literal: true

class PlayerChannel < ApplicationCable::Channel
  def stream_name
    "player_channel_#{params[:user_id]}"
  end

  def profile(json)
    player_profile = PlayerProfile.new(params[:user_id])
    render_response "profile", json, player_profile.as_ws_json
    PeriodicReward.receive_reward(params[:user_id])
  end

  def update_name(json)
    _json = JSON.parse(json['json'])
    new_name = _json['name']
    begin
      player.name = new_name
      player.save!
      render_response "update_name", json, { name: new_name }
    rescue ActiveRecord::RecordInvalid => e
      render_error "update_name", json, e.message, 400
    end
  end

  def daily_claim(json)
    _json = JSON.parse(json['json'])
    type = _json['type']

    begin
      # Map type to stamina amount
      stamina_amount = case type
                      when "daily" then 50
                      when "50" then 50  # Backward compatibility
                      else
                        render_error "daily_claim", json, "Invalid type. Use 'daily'", 400
                        return
                      end

      # Add stamina to player
      updated_player = player.add_stamina!(stamina_amount)
      
      # Return updated player data
      render_response "daily_claim", json, {
        player: {
          id: updated_player.id,
          stamina: updated_player.stamina
        },
        type: type,
        amount_added: stamina_amount
      }
    rescue StandardError => e
      Rails.logger.error "Daily claim error: #{e.message}\n#{e.backtrace.join("\n")}"
      render_error "daily_claim", json, "Internal server error", 500
    end
  end

  def hourly_claim(json)
    _json = JSON.parse(json['json'])
    type = _json['type']

    begin
      # Validate type
      unless type == "hourly"
        render_error "hourly_claim", json, "Invalid type. Use 'hourly'", 400
        return
      end

      # Calculate stamina to add with cap at 300
      current_stamina = player.stamina || 0
      max_stamina = 300
      
      stamina_amount = if current_stamina >= max_stamina
                        0  # Already at cap
                      elsif current_stamina + 10 <= max_stamina
                        10  # Add full amount
                      else
                        max_stamina - current_stamina  # Fill to cap
                      end

      # Add stamina to player
      updated_player = player.add_stamina!(stamina_amount)
      
      # Return updated player data
      render_response "hourly_claim", json, {
        player: {
          id: updated_player.id,
          stamina: updated_player.stamina
        },
        type: type,
        amount_added: stamina_amount
      }
    rescue StandardError => e
      Rails.logger.error "Hourly claim error: #{e.message}\n#{e.backtrace.join("\n")}"
      render_error "hourly_claim", json, "Internal server error", 500
    end
  end

  def summon_ally(json)
    _json = JSON.parse(json['json'])
    ally_name = _json['ally_name']
    shards_used = _json['shards_used']

    begin
      # Validate input parameters
      if ally_name.blank?
        render_error "summon_ally", json, "Ally name is required", 400
        return
      end

      if shards_used != 10
        render_error "summon_ally", json, "Must use exactly 10 shards to summon ally", 400
        return
      end

      # Initialize summoned_allies if nil (for existing players)
      player.summoned_allies ||= []
      
      # Check if ally already summoned
      if player.summoned_allies.include?(ally_name)
        render_error "summon_ally", json, "Ally already summoned", 400
        return
      end

      # Check if player has enough shards
      shard_item_name = ally_name # This should match the fragment_name from base_sidekicks.csv
      player.items_json ||= {}
      current_shards = player.items_json[shard_item_name] || 0

      if current_shards < 10
        render_error "summon_ally", json, "Not enough shards. Need 10, have #{current_shards}", 400
        return
      end

      ApplicationRecord.transaction do
        # Deduct shards
        player.items_json[shard_item_name] = current_shards - 10
        
        # Add to summoned allies
        player.summoned_allies << ally_name
        
        # Find the BaseSidekick to create a Sidekick instance
        base_sidekick = BaseSidekick.find_by(fragment_name: ally_name)
        if base_sidekick.blank?
          render_error "summon_ally", json, "Invalid ally name", 400
          return
        end

        # Create a new Sidekick instance for the player
        new_sidekick = Sidekick.create!(
          base_id: base_sidekick.id,
          player_id: player.id,
          skill_level: 1,
          star: 1,
          is_deployed: false
        )

        # CRITICAL FIX: Use update! to ensure database persistence
        player.update!(
          items_json: player.items_json,
          summoned_allies: player.summoned_allies
        )

        # Return success response
        render_response "summon_ally", json, {
          success: true,
          ally_summoned: ally_name,
          shards_used: 10,
          player: {
            id: player.id,
            items_json: player.items_json,
            summoned_allies: player.summoned_allies
          },
          sidekick: {
            id: new_sidekick.id,
            base_id: new_sidekick.base_id,
            name: base_sidekick.name,
            cn_name: base_sidekick.cn_name,
            skill_level: new_sidekick.skill_level,
            star: new_sidekick.star
          }
        }
      end
    rescue StandardError => e
      Rails.logger.error "Summon ally error: #{e.message}\n#{e.backtrace.join("\n")}"
      render_error "summon_ally", json, "Internal server error", 500
    end
  end

  def update_sidekick_deployment(json)
    _json = JSON.parse(json['json'])
    deployed_base_ids =
    begin
      if !deployed_base_ids.is_a?(Array)
        render_error "update_sidekick_deployment", json, "deployed_ids must be an array", 400
        return
      end
      # Convert all to string for comparison (handles '01', 1, etc.)
      deployed_base_ids = deployed_base_ids.map(&:to_s)
      # Get all sidekicks for this player
      player_sidekicks = player.sidekicks
      ApplicationRecord.transaction do
        player_sidekicks.each do |sidekick|
          should_deploy = deployed_base_ids.include?(sidekick.base_id.to_s)
          Rails.logger.info "Sidekick #{sidekick.id} base_id #{sidekick.base_id} -> #{should_deploy} (deployed_ids: #{deployed_base_ids.inspect})"
          sidekick.update!(is_deployed: should_deploy)
        end
      end
      render_response "update_sidekick_deployment", json, {
        success: true,
        deployed_base_ids: deployed_base_ids
      }
    rescue StandardError => e
      Rails.logger.error "Update sidekick deployment error: #{e.message}\n#{e.backtrace.join("\n")}" 
      render_error "update_sidekick_deployment", json, "Internal server error", 500
    end
  end

  def get_level_up_cost(json)
    _json = JSON.parse(json['json'])
    ally_id = _json['ally_id']
    Rails.logger.info "[WS get_level_up_cost] Incoming ally_id: #{ally_id}"
    
    begin
      # Find sidekick template
      base_sidekick = BaseSidekick.find_by(fragment_name: ally_id)
      Rails.logger.info "[WS get_level_up_cost] BaseSidekick lookup result: #{base_sidekick.inspect}"
      if base_sidekick.nil?
        Rails.logger.error "[WS get_level_up_cost] Ally not found for fragment_name: #{ally_id}"
        render_error "get_level_up_cost", json, "Ally not found", 400
        return
      end
      
      # Find player's sidekick instance
      player_sidekick = player.sidekicks.find_by(base_id: base_sidekick.id)
      if player_sidekick.nil?
        render_error "get_level_up_cost", json, "Player doesn't own this ally", 400
        return
      end
      
      current_level = player_sidekick.skill_level
      
      # Get all upgrade levels for this specific sidekick (match REST API logic)
      upgrade_levels = BaseSkillLevelUpEffect.where(skill_id: base_sidekick.skill_id)
        .select { |upgrade| 
          effects = JSON.parse(upgrade.effects || '{}')
          effects['sidekick_fragment_name'] == ally_id
        }
        .sort_by(&:level)
        .map do |upgrade|
          {
            level: "L#{upgrade.level.to_s.rjust(2, '0')}",
            description: upgrade.description,
            cost: upgrade.weight,
            is_unlocked: current_level >= upgrade.level
          }
        end
      
      # Get max level from upgrade_levels (if present)
      max_level = upgrade_levels.map { |u| u[:level].gsub('L', '').to_i }.max || 0
      
      # Get cost for next level
      next_level = current_level + 1
      next_upgrade = upgrade_levels.find { |u| u[:level] == "L#{next_level.to_s.rjust(2, '0')}" }
      
      if next_upgrade.nil?
        render_response "get_level_up_cost", json, {
          ally_id: ally_id,
          current_level: current_level,
          max_level: max_level,
          can_level_up: false,
          message: "Already at maximum level or no upgrade data",
          upgrade_levels: upgrade_levels
        }
        return
      end
      
      # Get skillbook name for this sidekick
      skillbook_name = "SKb_#{ally_id}"
      
      # Check player's resources
      player_gold = player.gold_coin || 0
      player_skillbooks = player.items_json&.dig(skillbook_name) || 0
      
      render_response "get_level_up_cost", json, {
        ally_id: ally_id,
        current_level: current_level,
        next_level: next_level,
        max_level: max_level,
        can_level_up: true,
        cost: {
          skillbook_cost: next_upgrade[:cost],
          gold_cost: next_upgrade[:cost] # If you have gold_cost, use it here
        },
        player_resources: {
          gold: player_gold,
          skillbooks: player_skillbooks
        },
        has_enough_resources: player_gold >= (next_upgrade[:cost] || 0) && 
                             player_skillbooks >= (next_upgrade[:cost] || 0),
        upgrade_levels: upgrade_levels
      }
    rescue StandardError => e
      Rails.logger.error "Get level up cost error: #{e.message}\n#{e.backtrace.join("\n")}" 
      render_error "get_level_up_cost", json, "Internal server error", 500
    end
  end

  def level_up_ally(json)
    _json = JSON.parse(json['json'])
    ally_id = _json['ally_id']
    
    begin
      # Find sidekick template
      base_sidekick = BaseSidekick.find_by(fragment_name: ally_id)
      if base_sidekick.nil?
        render_error "level_up_ally", json, "Ally not found", 400
        return
      end
      
      # Find player's sidekick instance
      player_sidekick = player.sidekicks.find_by(base_id: base_sidekick.id)
      if player_sidekick.nil?
        render_error "level_up_ally", json, "Player doesn't own this ally", 400
        return
      end
      
      current_level = player_sidekick.skill_level
      
      # Get max level from CSV data
      costs = CsvConfig.load_level_up_costs
      max_level = costs.map { |cost| cost[:level] }.max
      
      # Check if already at max level
      if current_level >= max_level
        render_error "level_up_ally", json, "Already at maximum level", 400
        return
      end
      
      # Get cost for next level
      next_level_cost = costs.find { |cost| cost[:level] == current_level + 1 }
      
      if next_level_cost.nil?
        render_error "level_up_ally", json, "No cost data for next level", 500
        return
      end
      
      # Get skillbook name for this sidekick
      skillbook_name = "SKb_#{ally_id}"
      
      # Check player's resources
      player_gold = player.gold_coin || 0
      player_skillbooks = player.items_json&.dig(skillbook_name) || 0
      
      required_gold = next_level_cost[:gold_cost]
      required_skillbooks = next_level_cost[:skillbook_cost]
      
      # Validate resources
      if player_gold < required_gold
        render_error "level_up_ally", json, "Insufficient gold: required #{required_gold}, have #{player_gold}", 400
        return
      end
      
      if player_skillbooks < required_skillbooks
        render_error "level_up_ally", json, "Insufficient skillbooks: required #{required_skillbooks}, have #{player_skillbooks}", 400
        return
      end
      
      # Perform level up in transaction
      ApplicationRecord.transaction do
        # Deduct gold
        player.gold_coin -= required_gold
        
        # Deduct skillbooks
        player.items_json = player.items_json || {}
        player.items_json[skillbook_name] = player_skillbooks - required_skillbooks
        
        # Level up sidekick
        player_sidekick.skill_level += 1
        
        # Save all changes
        player.save!
        player_sidekick.save!
      end
      
      render_response "level_up_ally", json, {
        ally_id: ally_id,
        old_level: current_level,
        new_level: player_sidekick.skill_level,
        costs_paid: {
          gold: required_gold,
          skillbooks: required_skillbooks
        },
        remaining_resources: {
          gold: player.gold_coin,
          skillbooks: player.items_json[skillbook_name]
        },
        can_level_up_again: player_sidekick.skill_level < max_level
      }
      
    rescue StandardError => e
      Rails.logger.error "Level up ally error: #{e.message}\n#{e.backtrace.join("\n")}" 
      render_error "level_up_ally", json, "Internal server error", 500
    end
  end

  def get_upgrade_levels(json)
    _json = JSON.parse(json['json'])
    ally_id = _json['ally_id']
    Rails.logger.info "[WS get_upgrade_levels] Incoming ally_id: #{ally_id}"
    begin
      base_sidekick = BaseSidekick.find_by(fragment_name: ally_id)
      Rails.logger.info "[WS get_upgrade_levels] BaseSidekick lookup result: #{base_sidekick.inspect}"
      if base_sidekick.nil?
        Rails.logger.error "[WS get_upgrade_levels] Ally not found for fragment_name: #{ally_id}"
        render_error "get_upgrade_levels", json, "Ally not found", 400
        return
      end
      # Find player's sidekick instance (may be nil if not owned)
      player_sidekick = player.sidekicks.find_by(base_id: base_sidekick.id)
      current_level = player_sidekick&.skill_level || 0
      upgrade_levels = BaseSkillLevelUpEffect.where(skill_id: base_sidekick.skill_id)
        .select { |upgrade| 
          effects = JSON.parse(upgrade.effects || '{}')
          effects['sidekick_fragment_name'] == ally_id
        }
        .sort_by(&:level)
        .map do |upgrade|
          {
            level: "L#{upgrade.level.to_s.rjust(2, '0')}",
            description: upgrade.description,
            is_unlocked: current_level >= upgrade.level
          }
        end
      render_response "get_upgrade_levels", json, {
        ally_id: ally_id,
        name: base_sidekick.name,
        cn_name: base_sidekick.cn_name,
        current_level: current_level,
        upgrade_levels: upgrade_levels
      }
    rescue StandardError => e
      Rails.logger.error "Get upgrade levels error: #{e.message}\n#{e.backtrace.join("\n")}" 
      render_error "get_upgrade_levels", json, "Internal server error", 500
    end
  end
end
