class AddUpgradeRankToEquipments < ActiveRecord::Migration[7.1]
  def change
    add_column :equipments, :upgrade_rank, :integer, default: 1, null: false, comment: "Upgrade rank (1-12) for percentage attack bonus"
  end
end
