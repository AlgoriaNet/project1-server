# frozen_string_literal: true

class PlayerLevelChannel < ApplicationCable::Channel
  
  # Get current level information based on player's EXP
  def get_level_info(json)
    begin
      # Get level info using LevelService
      level_info = LevelService.get_level_info(player)
      
      # Return level information
      render_response "get_level_info", json, {
        level_info: level_info,
        updated_player: player.reload.as_ws_json
      }
      
    rescue StandardError => e
      Rails.logger.error "Level info error: #{e.message}\n#{e.backtrace.join("\n")}"
      render_error "get_level_info", json, "Failed to get level info: #{e.message}", 500
    end
  end

  # Refresh level after EXP gain (called after battles, etc.)
  def refresh_level(json)
    begin
      # This method can be called after any EXP-gaining activity
      # It will automatically update the player's level if needed
      level_info = LevelService.get_level_info(player)
      
      render_response "refresh_level", json, {
        level_info: level_info,
        updated_player: player.reload.as_ws_json
      }
      
    rescue StandardError => e
      Rails.logger.error "Refresh level error: #{e.message}\n#{e.backtrace.join("\n")}"
      render_error "refresh_level", json, "Failed to refresh level: #{e.message}", 500
    end
  end
end