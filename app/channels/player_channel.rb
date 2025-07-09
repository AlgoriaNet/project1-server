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
    deployed_base_ids = _json['deployed_ids']
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
end
