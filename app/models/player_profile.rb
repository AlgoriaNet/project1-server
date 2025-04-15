# frozen_string_literal: true

class PlayerProfile
  def initialize(player_id)
    @player_id = player_id
    @player = Player.find(player_id)
  end

  def as_ws_json
    {
      Player: @player.as_ws_json.merge({
                                         equipments: Equipment.includes(:base_equipment).where(player_id: @player_id).reload.map(&:as_ws_json),
                                         gemstones: Gemstone.includes(:gemstone_entry).where(player_id: @player_id).reload.map(&:as_ws_json),
                                       }),
    }
  end
end
