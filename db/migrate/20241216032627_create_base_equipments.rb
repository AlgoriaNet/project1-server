class CreateBaseEquipments < ActiveRecord::Migration[7.1]
  def change
    create_table :base_equipments do |t|
      t.string :description, null: false
      t.string :name, limit: 30, null: false
      t.string :quality, limit: 20, null: false, comment: '品质'
      t.string :part, null: false, comment: "部位"
      t.integer :base_atk, null: false, comment: "基础攻击力"
      t.integer :growth_atk, null: false, comment: "成长攻击力"

      t.timestamps
    end
  end
end

