class CreateSidekicks < ActiveRecord::Migration[7.1]
  def change
    create_table :sidekicks do |t|
      t.integer :base_id
      t.integer :skill_level
      t.integer :star
      t.boolean :is_deployed
      t.integer :player_id
      t.timestamps
    end
  end
end
