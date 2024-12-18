# frozen_string_literal: true

class PlayerProfile
  def initialize(player_id)
    @player_id = player_id
    @player = Player.find(player_id)
  end

  def as_ws_json
    {
      Player: @player.as_ws_json,
    }
  end
end
