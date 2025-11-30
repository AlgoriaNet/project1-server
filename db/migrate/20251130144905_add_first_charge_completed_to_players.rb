class AddFirstChargeCompletedToPlayers < ActiveRecord::Migration[7.1]
  def change
    add_column :players, :first_charge_completed, :boolean, default: false
  end
end
