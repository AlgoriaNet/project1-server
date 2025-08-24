class AddDeployedSidekickIdsToPlayers < ActiveRecord::Migration[7.1]
  def change
    add_column :players, :deployed_sidekick_ids, :text
    
    # Initialize existing players with empty array
    reversible do |dir|
      dir.up do
        execute "UPDATE players SET deployed_sidekick_ids = '[]' WHERE deployed_sidekick_ids IS NULL"
      end
    end
  end
end
