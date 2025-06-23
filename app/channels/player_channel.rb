# frozen_string_literal: true

class PlayerChannel < ApplicationCable::Channel
  def stream_name
    "player_channel_#{params[:user_id]}"
  end

  def profile(json)
    player_profile = PlayerProfile.new(params[:user_id])
    render_response "profile", json, player_profile.as_ws_json
    PeriodicReward.receive_reward(params[:user_id])
  end

  def update_name(json)
    _json = JSON.parse(json['json'])
    new_name = _json['name']
    begin
      player.name = new_name
      player.save!
      render_response "update_name", json, { name: new_name }
    rescue ActiveRecord::RecordInvalid => e
      render_error "update_name", json, e.message, 400
    end
  end

end
