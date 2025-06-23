class AddDeviceIdToPlayers < ActiveRecord::Migration[7.1]
  def change
    add_column :players, :device_id, :string
    add_index :players, :device_id, unique: true
  end
end

