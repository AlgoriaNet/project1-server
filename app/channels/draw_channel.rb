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

      response_data = {
        items: rewards,
        Player: player.as_ws_json,
      }

      # Include free claim counts if this was a free ad-based draw
      if _json["consume_item"]&.downcase == "ad"
        response_data[:free_claims] = get_free_claim_counts(player)
      end

      if _json["card_pool_type"] == "hero"
        render_response "draw", json, response_data
      else
        response_data[:gems] = rewards.map(&:as_ws_json)
        response_data[:all_gems] = player.reload.gemstones.includes(:gemstone_entry, :secondary_gemstone_entry).map(&:as_ws_json)
        render_response "draw", json, response_data
      end

    rescue Exception => e
      render_error "draw", json, e.message
    end
  end

  private

  def get_free_claim_counts(player)
    player.draw_times ||= {}
    free_claims = player.draw_times['free_claims'] || {}

    {
      hero: free_claims['hero']&.[]('count') || 0,
      rare: free_claims['rare']&.[]('count') || 0,
      epic: free_claims['epic']&.[]('count') || 0
    }
  end
end
