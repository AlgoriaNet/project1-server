class RenameMaxStageToMaxUnlockedStage < ActiveRecord::Migration[7.1]
  def change
    rename_column :players, :max_stage, :max_unlocked_stage
  end
end
