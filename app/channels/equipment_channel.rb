# frozen_string_literal: true

class EquipmentChannel < ApplicationCable::Channel

  def stream_name
    "equipment_channel_#{params[:user_id]}"
  end

  def replace(json)
    ActiveRecord::Base.uncached do
      params = JSON.parse(json['json'])
      puts params
      case params['type']
      when 'hero'
        living = @player.hero
      when 'sidekick'
        return if params['sidekickId'].blank?
        living = @player.sidekicks.where(id: params['sidekickId']).first
        return if living.blank?
      else
        # type code here
      end
      return if params['equipmentId'].blank?
      equipment = @player.equipments.where(id: params['equipmentId']).first
      return if equipment.blank?

      equipment.equip_with(living)

      player_profile = PlayerProfile.new(@player_id)
      render_response "replace", json, player_profile.as_ws_json
    end
  end
end
