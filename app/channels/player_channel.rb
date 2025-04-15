# frozen_string_literal: true

class PlayerChannel < ApplicationCable::Channel
  def stream_name
    "player_channel_#{params[:user_id]}"
  end

  def profile(json)
    player_profile = PlayerProfile.new(params[:user_id])
    render_response "profile", json, player_profile.as_ws_json
  end
end
