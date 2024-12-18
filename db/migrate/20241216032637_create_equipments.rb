class CreateEquipments < ActiveRecord::Migration[7.1]
  def change
    create_table :equipments do |t|
      t.bigint :base_equipment_id, null: false
      t.integer :intensify_level, default: 0, null: false, comment: "强化等级"
      t.text :nearby_attributes, "额外词条"
      t.bigint :player_id, null: false
      t.bigint :equip_with_sidekick_id
      t.bigint :equip_with_hero_id
      t.timestamps

      # 添加索引
      t.index [:base_equipment_id], name: 'equipments_base_equipments_id_fk'
      t.index [:equip_with_hero_id], name: 'equipments_heros_id_fk'
      t.index [:player_id], name: 'equipments_players_id_fk'
      t.index [:equip_with_sidekick_id], name: 'equipments_sidekicks_id_fk'

    end
    add_foreign_key :equipments, :base_equipments, column: :base_equipment_id, name: 'equipments_base_equipments_id_fk'
    add_foreign_key :equipments, :heros, column: :equip_with_hero_id, name: 'equipments_heros_id_fk'
    add_foreign_key :equipments, :players, column: :player_id, name: 'equipments_players_id_fk'
    add_foreign_key :equipments, :sidekicks, column: :equip_with_sidekick_id, name: 'equipments_sidekicks_id_fk'
  end
end
