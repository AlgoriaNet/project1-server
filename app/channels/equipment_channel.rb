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

end
