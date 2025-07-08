# frozen_string_literal: true

class DrawChannel < ApplicationCable::Channel
  def stream_name
    "draw_channel_#{params[:user_id]}"
  end

  def draw(json)
    _json = JSON.parse(json['json'])
    begin
      player = Player.find(params[:user_id])
      rewards = DrawService.new(params[:user_id], _json).draw
      # Reload player to get updated heroKey and items_json after DrawService
      player.reload
      if _json["card_pool_type"] == "hero"
        render_response "draw", json, {
          items: rewards,
          Player: player.as_ws_json,
        }
      else
        render_response "draw", json, {
          gems: rewards.map(&:as_ws_json),
          all_gems: player.reload.gemstones.map(&:as_ws_json),
          Player: player.as_ws_json,
        }
      end

    rescue Exception => e
      render_error "draw", json, e.message
    end
  end
end
