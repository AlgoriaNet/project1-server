class AddThemeAndStageToMainStages < ActiveRecord::Migration[7.1]
  def change
    add_column :main_stages, :theme_id, :integer
    add_column :main_stages, :stage_in_theme, :integer
    add_column :main_stages, :monsters_config, :json
  end
end
