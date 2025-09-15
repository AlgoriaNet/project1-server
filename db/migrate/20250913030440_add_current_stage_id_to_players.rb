class AddCurrentStageIdToPlayers < ActiveRecord::Migration[7.1]
  def change
    add_column :players, :current_stage_id, :integer, null: false, default: 1, comment: 'Current battle stage (1-100)'
    add_index :players, :current_stage_id
  end
end
