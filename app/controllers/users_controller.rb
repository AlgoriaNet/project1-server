class UsersController < ApplicationController
  skip_before_action :verify_authenticity_token
  def guest_login
    device_id = params[:device_id]
    player = Player.where(device_id: device_id).first
    if player.blank?
      player = Player.create(device_id: device_id, name: "游客_#{device_id[0..5]}")
      player.save!
    end
    render json: {id: player.id}, status: :ok
  end
end
