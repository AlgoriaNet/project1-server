class AddDisplayNameToBaseEquipments < ActiveRecord::Migration[7.1]
  def change
    add_column :base_equipments, :display_name, :string
  end
end
