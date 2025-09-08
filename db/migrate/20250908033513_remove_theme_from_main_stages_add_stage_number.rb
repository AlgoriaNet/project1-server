class RemoveThemeFromMainStagesAddStageNumber < ActiveRecord::Migration[7.1]
  def change
    remove_column :main_stages, :theme_id, :integer
    remove_column :main_stages, :stage_in_theme, :integer
    add_column :main_stages, :stage_number, :integer
  end
end
