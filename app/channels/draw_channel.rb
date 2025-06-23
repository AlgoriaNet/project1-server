# frozen_string_literal: true

class DrawChannel < ApplicationCable::Channel
  def stream_name
    "draw_channel_#{params[:user_id]}"
  end

  def draw(json)
    _json = JSON.parse(json['json'])
    card_pool_type = _json['card_pool_type']
    consume_item = _json['consume_item']
    count = _json['count']
    player = Player.find(params[:user_id])
    begin
      case card_pool_type
      when 'rare gem'
        gems = Unboxing.generate_gemstone_by_times(params[:user_id], count)
        render_response "draw", json, {
          gems: gems.map(&:as_ws_json),
          all_gems: player.gemstones.map(&:as_ws_json)
        }
      when 'epic gem'
        gems = Unboxing.unusual_gemstone_by_times(params[:user_id], count)
        render_response "draw", json, {
          gems: gems.map(&:as_ws_json),
          all_gems: player.gemstones.map(&:as_ws_json)
        }
      when 'hero'
      end

    end

  end



end
