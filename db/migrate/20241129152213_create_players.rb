class CreatePlayers < ActiveRecord::Migration[7.1]
  def change
    create_table :players do |t|
      t.string :name
      t.integer :deployed_sidekick1_id
      t.integer :deployed_sidekick2_id
      t.integer :deployed_sidekick3_id
      t.integer :deployed_sidekick4_id

      t.timestamps
    end
  end
end
