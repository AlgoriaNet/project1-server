class AddPrimaryIndexToPlayers < ActiveRecord::Migration[7.1]
  def change
    # Note: Players table already has id as primary key by default
    # This adds a composite index for faster lookups when both id and device_id are queried
    # Helps optimize player.reload() operations during battle completion
    add_index :players, [:id, :device_id], name: :index_players_on_id_and_device_id, if_not_exists: true
  end
end
