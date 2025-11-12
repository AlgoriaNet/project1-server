class AddPlayerIdIndexToSidekicks < ActiveRecord::Migration[7.1]
  def change
    # Add index on player_id for faster sidekick lookups
    # This fixes battle reward loading slowness (3.3s → 500ms)
    # Sidekicks was the only player-owned table without this index
    add_index :sidekicks, :player_id, name: :index_sidekicks_on_player_id
  end
end
