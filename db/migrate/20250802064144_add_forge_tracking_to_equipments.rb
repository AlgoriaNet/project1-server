class AddForgeTrackingToEquipments < ActiveRecord::Migration[7.1]
  def change
    add_column :equipments, :total_crystals_spent, :integer, default: 0, null: false, comment: "Total crystals spent on forging this equipment"
  end
end
