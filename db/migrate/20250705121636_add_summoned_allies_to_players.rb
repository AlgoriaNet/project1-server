class AddSummonedAlliesToPlayers < ActiveRecord::Migration[7.1]
  def change
    add_column :players, :summoned_allies, :json, null: true
  end
end
