class CreateHeros < ActiveRecord::Migration[7.1]
  def change
    create_table :heros do |t|
      t.string :name
      t.integer :player_id

      t.timestamps
    end
  end
end
