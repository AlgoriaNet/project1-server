class AddMaxStageToPlayers < ActiveRecord::Migration[7.1]
  def change
    add_column :players, :max_stage, :integer, null: false, default: 1, comment: 'Highest unlocked stage (1-100)'
    add_index :players, :max_stage
  end
end
