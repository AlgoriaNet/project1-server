# frozen_string_literal: true

class PlayerChannel < ApplicationCable::Channel
  def subscribed
    stream_from "Player_#{params[:user_id]}"
  end

  def profile(json)
    player_profile = PlayerProfile.new(params[:user_id])
    ActionCable.server.broadcast("Player_#{params[:user_id]}",
                                 { action: "profile", code: 200,  requestId: json["requestId"], data: player_profile.as_ws_json })
  end
end
