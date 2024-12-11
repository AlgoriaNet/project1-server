class CreateBaseSkills < ActiveRecord::Migration[7.1]
  def change
    create_table :base_skills do |t|
      t.string :name
      t.string :nature
      t.float :cd
      t.integer :releases_count
      t.float :frequency
      t.float :damage_ratio
      t.json :levelUpSetting

      t.timestamps
    end
  end
end
