class AddStatsToMonsters < ActiveRecord::Migration[7.1]
  def change
    add_column :monsters, :level, :integer
    add_column :monsters, :hp, :integer
    add_column :monsters, :atk, :integer
    add_column :monsters, :speed, :float
    add_column :monsters, :abilities, :json
    add_column :monsters, :rewards, :json
  end
end
