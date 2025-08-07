# frozen_string_literal: true

class EquipmentChannel < ApplicationCable::Channel

  def stream_name
    "equipment_channel_#{params[:user_id]}"
  end

  def equip(json)
    ActiveRecord::Base.uncached do
      @player.reload  # Prevent stale inventory data
      params = JSON.parse(json['json'])
      puts "equip params: #{params}"
      
      case params['type']
      when 'hero'
        living = @player.hero
      when 'sidekick'
        return render_error("equip", json, "Sidekick ID is required") if params['sidekickId'].blank?
        living = @player.sidekicks.where(id: params['sidekickId']).first
        return render_error("equip", json, "Sidekick not found") if living.blank?
      else
        return render_error("equip", json, "Invalid type. Must be 'hero' or 'sidekick'")
      end
      
      return render_error("equip", json, "Equipment ID is required") if params['equipmentId'].blank?
      equipment = @player.equipments.where(id: params['equipmentId']).first
      return render_error("equip", json, "Equipment not found") if equipment.blank?

      # Check if equipment is already equipped
      if equipment.is_equipped?
        return render_error("equip", json, "Equipment is already equipped")
      end

      # Check if the same equipment part is already equipped (for equip, we don't auto-replace)
      equipped_in_same_part = living.equipments.reload.to_a.select { |equip| equip.base_equipment.part == equipment.base_equipment.part }
      if equipped_in_same_part.any?
        return render_error("equip", json, "Equipment slot is already occupied. Use replace instead.")
      end

      success = equipment.equip_with(living)
      if success
        player_profile = PlayerProfile.new(@player_id)
        render_response "equip", json, {
          success: true,
          type: params['type'],
          sidekickId: params['sidekickId'],
          equipmentId: params['equipmentId'],
          player_profile: player_profile.as_ws_json
        }
      else
        render_error("equip", json, "Failed to equip equipment")
      end
    end
  end

  def replace(json)
    ActiveRecord::Base.uncached do
      @player.reload  # Prevent stale inventory data
      params = JSON.parse(json['json'])
      puts "replace params: #{params}"
      
      case params['type']
      when 'hero'
        living = @player.hero
      when 'sidekick'
        return render_error("replace", json, "Sidekick ID is required") if params['sidekickId'].blank?
        living = @player.sidekicks.where(id: params['sidekickId']).first
        return render_error("replace", json, "Sidekick not found") if living.blank?
      else
        return render_error("replace", json, "Invalid type. Must be 'hero' or 'sidekick'")
      end
      
      return render_error("replace", json, "Equipment ID is required") if params['equipmentId'].blank?
      equipment = @player.equipments.where(id: params['equipmentId']).first
      return render_error("replace", json, "Equipment not found") if equipment.blank?

      success = equipment.equip_with(living)
      if success
        player_profile = PlayerProfile.new(@player_id)
        render_response "replace", json, {
          success: true,
          type: params['type'],
          sidekickId: params['sidekickId'],
          equipmentId: params['equipmentId'],
          player_profile: player_profile.as_ws_json
        }
      else
        render_error("replace", json, "Failed to replace equipment")
      end
    end
  end

  def dismantle(json)
    ActiveRecord::Base.uncached do
      @player.reload  # Prevent stale inventory data
      params = JSON.parse(json['json'])
      puts "dismantle params: #{params}"
      
      return render_error("dismantle", json, "Equipment ID is required") if params['equipmentId'].blank?
      equipment = @player.equipments.where(id: params['equipmentId']).first
      return render_error("dismantle", json, "Equipment not found") if equipment.blank?
      
      # Dismantle the equipment
      result = equipment.dismantle
      
      if result[:success]
        @player.reload # Refresh player data after dismantle
        player_profile = PlayerProfile.new(@player_id)
        render_response "dismantle", json, {
          success: true,
          equipmentId: params['equipmentId'],
          crystals_rewarded: result[:crystals_rewarded],
          base_crystals: result[:base_crystals],
          refund_crystals: result[:refund_crystals],
          player_profile: player_profile.as_ws_json[:Player]
        }
      else
        render_error("dismantle", json, result[:error] || "Failed to dismantle equipment")
      end
    end
  end
  
  # Enhancement API
  def enhance(json)
    ActiveRecord::Base.uncached do
      @player.reload # Prevent stale data
      
      begin
        params = JSON.parse(json['json'])
      rescue JSON::ParserError => e
        render_error "enhance", json, "Invalid JSON format in request: #{e.message}", 400
        return
      end
      
      equipment_id = params['equipmentId']
      
      if equipment_id.blank?
        render_error "enhance", json, "Equipment ID is required", 400
        return
      end
      
      equipment = @player.equipments.find_by(id: equipment_id)
      if equipment.blank?
        render_error "enhance", json, "Equipment not found", 404
        return
      end
      
      # Get preview data before enhancement
      preview = equipment.enhancement_preview
      current_attack = equipment.total_attack
      
      # Perform enhancement
      result = equipment.intensify
      
      if result[:success]
        @player.reload # Refresh player data after enhancement
        equipment.reload # Ensure equipment data is fresh
        
        # Create PlayerProfile AFTER all equipment operations are complete
        player_profile = PlayerProfile.new(@player_id)
        
        render_response "enhance", json, {
          success: true,
          equipment_id: equipment_id,
          # UI-friendly before/after data
          before: {
            level: result[:old_level],
            attack: current_attack
          },
          after: {
            level: result[:new_level], 
            attack: result[:total_attack]
          },
          # Enhancement details
          cost_paid: result[:cost_paid],
          attack_increase: result[:total_attack] - current_attack,
          updated_equipment: equipment.as_ws_json,
          player_profile: player_profile.as_ws_json[:Player]
        }
      else
        render_error "enhance", json, result[:error] || "Enhancement failed", 400
      end
    end
  end
  
  # Auto Enhancement API
  def auto_enhance(json)
    ActiveRecord::Base.uncached do
      @player.reload # Prevent stale data
      
      begin
        params = JSON.parse(json['json'])
      rescue JSON::ParserError => e
        render_error "auto_enhance", json, "Invalid JSON format in request: #{e.message}", 400
        return
      end
      
      equipment_id = params['equipmentId']
      target_level = params['targetLevel']
      
      if equipment_id.blank?
        render_error "auto_enhance", json, "Equipment ID is required", 400
        return
      end
      
      equipment = @player.equipments.find_by(id: equipment_id)
      if equipment.blank?
        render_error "auto_enhance", json, "Equipment not found", 404
        return
      end
      
      # Perform auto enhancement
      result = equipment.auto_intensify(target_level)
      
      if result[:success]
        @player.reload # Refresh player data after enhancement
        equipment.reload # Ensure equipment data is fresh
        
        # Create PlayerProfile AFTER all equipment operations are complete
        player_profile = PlayerProfile.new(@player_id)
        
        render_response "auto_enhance", json, {
          success: true,
          equipment_id: equipment_id,
          enhancements_performed: result[:enhancements_performed],
          final_level: result[:final_level],
          total_cost: result[:total_cost],
          updated_equipment: equipment.as_ws_json,
          player_profile: player_profile.as_ws_json[:Player]
        }
      else
        render_error "auto_enhance", json, result[:error] || "Auto enhancement failed", 400
      end
    end
  end
  
  # Get enhancement cost preview
  def enhancement_cost(json)
    begin
      params = JSON.parse(json['json'])
    rescue JSON::ParserError => e
      render_error "enhancement_cost", json, "Invalid JSON format in request: #{e.message}", 400
      return
    end
    
    equipment_id = params['equipmentId']
    
    if equipment_id.blank?
      render_error "enhancement_cost", json, "Equipment ID is required", 400
      return
    end
    
    equipment = @player.equipments.find_by(id: equipment_id)
    if equipment.blank?
      render_error "enhancement_cost", json, "Equipment not found", 404
      return
    end
    
    preview = equipment.enhancement_preview
    if preview.nil?
      render_error "enhancement_cost", json, "Equipment cannot be enhanced further", 400
      return
    end
    
    current_crystals = @player.items_json["crystal"] || 0
    current_gold = @player.gold_coin || 0
    
    render_response "enhancement_cost", json, {
      equipment_id: equipment_id,
      # UI-friendly preview data
      current: {
        level: preview[:current_level],
        attack: preview[:current_attack]
      },
      next: {
        level: preview[:next_level],
        attack: preview[:next_attack]
      },
      # Cost and affordability
      cost: preview[:cost],
      attack_increase: preview[:attack_increase],
      can_afford: current_crystals >= preview[:cost][:crystals] && current_gold >= preview[:cost][:gold],
      player_resources: { crystals: current_crystals, gold: current_gold }
    }
  end

  # Washing API - Re-roll equipment attributes for 200 crystals
  def wash(json)
    ActiveRecord::Base.uncached do
      @player.reload # Prevent stale data
      
      begin
        params = JSON.parse(json['json'])
      rescue JSON::ParserError => e
        render_error "wash", json, "Invalid JSON format in request: #{e.message}", 400
        return
      end
      
      equipment_id = params['equipmentId']
      
      if equipment_id.blank?
        render_error "wash", json, "Equipment ID is required", 400
        return
      end
      
      equipment = @player.equipments.find_by(id: equipment_id)
      if equipment.blank?
        render_error "wash", json, "Equipment not found", 404
        return
      end
      
      # Check if player has enough crystals
      current_crystals = @player.items_json["crystal"] || 0
      wash_cost = 200
      
      if current_crystals < wash_cost
        render_error "wash", json, "Insufficient crystals. Need #{wash_cost} crystals.", 400
        return
      end
      
      # Store old attributes for comparison
      old_attributes = equipment.nearby_attributes.dup
      
      ApplicationRecord.transaction do
        # Deduct crystals from player first
        @player.remove_item!("crystal", wash_cost, "equipment_washing")
        
        # Perform washing (re-roll attributes) - crystals are gone forever, not refundable
        equipment.washing
      end
      
      @player.reload # Refresh player data after washing
      equipment.reload # Ensure equipment data is fresh
      
      # Create PlayerProfile AFTER all equipment operations are complete
      player_profile = PlayerProfile.new(@player_id)
      
      render_response "wash", json, {
        success: true,
        equipment_id: equipment_id,
        cost_paid: wash_cost,
        old_attributes: old_attributes,
        new_attributes: equipment.nearby_attributes,
        updated_equipment: equipment.as_ws_json,
        player_profile: player_profile.as_ws_json
      }
    end
  rescue => e
    Rails.logger.error "Washing API error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    render_error "wash", json, "Washing failed: #{e.message}", 500
  end

  # Upgrade Rank API - Increase equipment rank for percentage attack bonus
  def upgrade_rank(json)
    ActiveRecord::Base.uncached do
      @player.reload # Prevent stale data
      
      begin
        params = JSON.parse(json['json'])
      rescue JSON::ParserError => e
        render_error "upgrade_rank", json, "Invalid JSON format in request: #{e.message}", 400
        return
      end
      
      equipment_id = params['equipmentId']
      
      if equipment_id.blank?
        render_error "upgrade_rank", json, "Equipment ID is required", 400
        return
      end
      
      equipment = @player.equipments.find_by(id: equipment_id)
      if equipment.blank?
        render_error "upgrade_rank", json, "Equipment not found", 404
        return
      end
      
      # Perform rank upgrade
      result = equipment.upgrade_quality
      
      if result[:success]
        @player.reload # Refresh player data after upgrade
        equipment.reload # Ensure equipment data is fresh
        
        # Create PlayerProfile AFTER all equipment operations are complete
        player_profile = PlayerProfile.new(@player_id)
        
        render_response "upgrade_rank", json, {
          success: true,
          equipment_id: equipment_id,
          # UI-friendly before/after data (similar to enhance API)
          before: {
            rank: result[:old_rank],
            attack: result[:old_attack],
            percentage: result[:old_percentage],
            color: result[:old_color]
          },
          after: {
            rank: result[:new_rank],
            attack: result[:new_attack],
            percentage: result[:new_percentage], 
            color: result[:new_color]
          },
          # Upgrade details
          cost_paid: result[:cost_paid],
          attack_increase: result[:attack_increase],
          updated_equipment: equipment.as_ws_json,
          player_profile: player_profile.as_ws_json[:Player]
        }
      else
        render_error "upgrade_rank", json, result[:error] || "Rank upgrade failed", 400
      end
    end
  rescue => e
    Rails.logger.error "Upgrade Rank API error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    render_error "upgrade_rank", json, "Rank upgrade failed: #{e.message}", 500
  end

  # Get upgrade rank cost preview
  def upgrade_rank_cost(json)
    begin
      params = JSON.parse(json['json'])
    rescue JSON::ParserError => e
      render_error "upgrade_rank_cost", json, "Invalid JSON format in request: #{e.message}", 400
      return
    end
    
    equipment_id = params['equipmentId']
    
    if equipment_id.blank?
      render_error "upgrade_rank_cost", json, "Equipment ID is required", 400
      return
    end
    
    equipment = @player.equipments.find_by(id: equipment_id)
    if equipment.blank?
      render_error "upgrade_rank_cost", json, "Equipment not found", 404
      return
    end
    
    preview = equipment.upgrade_rank_preview
    if preview.nil?
      render_error "upgrade_rank_cost", json, "Equipment cannot be upgraded further", 400
      return
    end
    
    current_skillbooks = @player.items_json["SKb_00_Hero"] || 0
    
    render_response "upgrade_rank_cost", json, {
      equipment_id: equipment_id,
      # UI-friendly preview data
      current: {
        rank: preview[:current_rank],
        attack: preview[:current_attack],
        percentage: preview[:current_percentage],
        color: preview[:current_color]
      },
      next: {
        rank: preview[:next_rank],
        attack: preview[:next_attack],
        percentage: preview[:next_percentage],
        color: preview[:next_color]
      },
      # Cost and affordability
      cost: preview[:cost],
      attack_increase: preview[:attack_increase],
      can_afford: current_skillbooks >= preview[:cost][:skillbooks],
      player_resources: { skillbooks: current_skillbooks }
    }
  end

end
