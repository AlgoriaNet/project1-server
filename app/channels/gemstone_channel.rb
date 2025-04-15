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

  def inlay(json)
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

  def outlay(json)
    params = JSON.parse(json['json'])
    gemstone_id = params['gemId']
    gemstone = @player.gemstones.where(player_id: @player_id, id: gemstone_id).first
    if gemstone.blank?
      render_error "outlay", json, "gemstone not found", 500
    else
      res = gemstone.outlay
      if res[:error]
        render_error "outlay", json, res[:error], 500
      else
        render_response "outlay", json, @player.gemstones.map(&:as_ws_json)
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
end
