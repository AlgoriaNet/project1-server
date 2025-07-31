# frozen_string_literal: true

class GemstoneChannel < ApplicationCable::Channel
  def stream_name
    "gemstone_channel_#{params[:user_id]}"
  end

  def gems
    Gemstone.includes(:gemstone_entry).where(player_id: params[:user_id]).map(&:as_ws_json)
  end

  def info
    render_response "info", {}, @player.gemstones.map(&:as_ws_json)
  end

  def lock(json)
    gemstone_id = json['gemstone_id']
    gemstone = @player.gemstones.where(player_id: @player_id, id: gemstone_id).first
    if gemstone.present?
      gemstone.lock.save!
      render_response "lock", json, @player.gemstones.map(&:as_ws_json)
    end
  end

  def unlock(json)
    gemstone_id = json['gemstone_id']
    gemstone = @player.gemstones.where(player_id: @player_id, id: gemstone_id).first
    if gemstone.present?
      gemstone.unlock.save!
      render_response "unlock", json, @player.gemstones.map(&:as_ws_json)
    end
  end

  # New equipment-based inlay API
  def inlay(json)
    params = JSON.parse(json['json'])
    gemstone_id = params['gemId']
    equipment_id = params['equipmentId']
    slot_number = params['slotNumber'] || 1
    
    # Legacy support for sidekickId parameter
    if params['sidekickId'].present? && equipment_id.blank?
      return legacy_inlay(json)
    end
    
    gemstone = @player.gemstones.find_by(id: gemstone_id)
    equipment = @player.equipments.find_by(id: equipment_id)
    
    if gemstone.blank?
      render_error "inlay", json, "Gemstone not found", 404
      return
    end
    
    if equipment.blank?
      render_error "inlay", json, "Equipment not found", 404
      return
    end
    
    if gemstone.is_embedded?
      render_error "inlay", json, "Gem is already embedded", 400
      return
    end
    
    result = gemstone.inlay_with_equipment(equipment, slot_number)
    
    if result[:success]
      @player.reload # Ensure fresh data
      render_response "inlay", json, {
        success: true,
        equipment_id: equipment_id,
        slot_number: slot_number,
        gem_id: gemstone_id,
        updated_equipment: equipment.reload.as_ws_json,
        inventory_gems: @player.gemstones.where(is_in_inventory: true).map(&:as_ws_json)
      }
    else
      render_error "inlay", json, result[:error], 400
    end
  end
  
  # Legacy inlay method for backward compatibility
  def legacy_inlay(json)
    params = JSON.parse(json['json'])
    gemstone_id = params['gemId']
    sidekick_id = params['sidekickId']

    if sidekick_id.present?
      living = @player.sidekicks.where(player_id: @player_id, id: sidekick_id).first
    else
      living = @player.hero
    end
    gemstone = Gemstone.where(player_id: @player_id, id: gemstone_id).first

    if living.blank?
      render_error "inlay", json, "living not found", 500
      return
    end
    if gemstone.blank?
      render_error "inlay", json, "gemstone not found", 500
      return
    end
    res = gemstone.inlay_with(living)
    if res == true
      render_response "inlay", json, { gems: gems }
    else
      render_error "inlay", json, "inlay failed", 500
    end
  end

  # New equipment-based outlay API
  def outlay(json)
    params = JSON.parse(json['json'])
    gemstone_id = params['gemId']
    equipment_id = params['equipmentId']
    slot_number = params['slotNumber']
    
    if equipment_id.present? && slot_number.present?
      # New equipment-based outlay
      equipment = @player.equipments.find_by(id: equipment_id)
      
      if equipment.blank?
        render_error "outlay", json, "Equipment not found", 404
        return
      end
      
      result = equipment.remove_gem(slot_number)
      
      if result[:success]
        @player.reload
        render_response "outlay", json, {
          success: true,
          equipment_id: equipment_id,
          slot_number: slot_number,
          updated_equipment: equipment.reload.as_ws_json,
          inventory_gems: @player.gemstones.where(is_in_inventory: true).map(&:as_ws_json)
        }
      else
        render_error "outlay", json, result[:error], 400
      end
    else
      # Legacy gemstone-based outlay
      gemstone = @player.gemstones.find_by(id: gemstone_id)
      
      if gemstone.blank?
        render_error "outlay", json, "Gemstone not found", 404
        return
      end
      
      if gemstone.is_embedded?
        result = gemstone.outlay_from_equipment
        if result[:success]
          @player.reload
          render_response "outlay", json, {
            success: true,
            gem_id: gemstone_id,
            inventory_gems: @player.gemstones.where(is_in_inventory: true).map(&:as_ws_json)
          }
        else
          render_error "outlay", json, result[:error], 400
        end
      else
        # Legacy outlay
        gemstone.outlay
        render_response "outlay", json, @player.gemstones.map(&:as_ws_json)
      end
    end
  end

  def replace(json)
    ActiveRecord::Base.uncached do
      @player.reload  # Prevent stale inventory data
      params = JSON.parse(json['json'])
      gemstone_id = params['gemId']
      equipment_id = params['equipmentId']
      slot_number = params['slotNumber']
      
      # Validate required parameters
      if gemstone_id.blank?
        render_error "replace", json, "Gem ID is required", 400
        return
      end
      
      if equipment_id.blank?
        render_error "replace", json, "Equipment ID is required", 400
        return
      end
      
      if slot_number.blank?
        render_error "replace", json, "Slot number is required", 400
        return
      end
      
      # Find gemstone and equipment
      gemstone = @player.gemstones.find_by(id: gemstone_id)
      equipment = @player.equipments.find_by(id: equipment_id)
      
      if gemstone.blank?
        render_error "replace", json, "Gemstone not found", 404
        return
      end
      
      if equipment.blank?
        render_error "replace", json, "Equipment not found", 404
        return
      end
      
      if gemstone.is_embedded?
        render_error "replace", json, "Gem is already embedded", 400
        return
      end
      
      # Check part compatibility
      if gemstone.part != equipment.base_equipment.part
        render_error "replace", json, "Gem part (#{gemstone.part}) doesn't match equipment part (#{equipment.base_equipment.part})", 400
        return
      end
      
      ApplicationRecord.transaction do
        # Remove existing gem from the slot if any
        existing_gem = equipment.gemstones.find_by(slot_number: slot_number)
        if existing_gem
          result = existing_gem.outlay_from_equipment
          unless result[:success]
            render_error "replace", json, "Failed to remove existing gem: #{result[:error]}", 500
            return
          end
        end
        
        # Embed the new gem
        result = gemstone.inlay_with_equipment(equipment, slot_number)
        if result[:success]
          @player.reload
          render_response "replace", json, {
            success: true,
            equipment_id: equipment_id,
            slot_number: slot_number,
            gem_id: gemstone_id,
            updated_equipment: equipment.reload.as_ws_json,
            inventory_gems: @player.gemstones.where(is_in_inventory: true).map(&:as_ws_json)
          }
        else
          render_error "replace", json, "Failed to embed new gem: #{result[:error]}", 500
        end
      end
    end
  end

  def upgrade(json)
    gemstone_ids = json['gemstone_ids']
    new = Gemstone.upgrade(@player_id, gemstone_ids)
    render_response "upgrade", json, new
  end

  def auto_upgrade(json)
    Gemstone.auto_upgrade(@player_id)
    render_response "auto_upgrade", json, { gems: @player.gemstones.map(&:as_ws_json) }
  end
  
  # New API: Get equipment gem status
  def equipment_gems(json)
    params = JSON.parse(json['json'])
    equipment_id = params['equipmentId']
    
    equipment = @player.equipments.find_by(id: equipment_id)
    
    if equipment.blank?
      render_error "equipment_gems", json, "Equipment not found", 404
      return
    end
    
    render_response "equipment_gems", json, {
      equipment_id: equipment_id,
      equipment: equipment.as_ws_json,
      gem_slots: equipment.get_embedded_gems_summary
    }
  end
end
