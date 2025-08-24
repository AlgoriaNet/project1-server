class RenameDeployedSidekickIdsToDeployedBaseIds < ActiveRecord::Migration[7.1]
  def change
    rename_column :players, :deployed_sidekick_ids, :deployed_base_ids
    
    # Reset all existing data to empty array since it contains wrong IDs
    reversible do |dir|
      dir.up do
        execute "UPDATE players SET deployed_base_ids = '[]'"
      end
    end
  end
end
