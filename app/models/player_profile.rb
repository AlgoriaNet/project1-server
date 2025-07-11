# frozen_string_literal: true

class PlayerProfile
  def initialize(player_id)
    @player_id = player_id
    @player = Player.find(player_id)
  end

  def as_ws_json
    # Reload player data to ensure fresh data for items like heroKey, rareKey, epicKey
    @player.reload
    player_data = @player.as_ws_json
    
    {
      Player: player_data.merge({
                                 equipments: Equipment.includes(:base_equipment).where(player_id: @player_id).reload.map(&:as_ws_json),
                                 gemstones: Gemstone.includes(:gemstone_entry).where(player_id: @player_id).reload.map(&:as_ws_json),
                                 sidekicks: Sidekick.includes(:base_sidekick).where(player_id: @player_id).reload.map(&:as_ws_json),
                               }),
    }
  end
end
