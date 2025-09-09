class AddCurrentStageToPlayers < ActiveRecord::Migration[7.1]
  def change
    add_column :players, :current_stage, :integer, default: 1
  end
end
