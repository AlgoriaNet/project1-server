class CreateBattleFormations < ActiveRecord::Migration[7.1]
  def change
    create_table :battle_formations do |t|
      t.bigint :player_id, null: false
      t.bigint :sidekick1_id
      t.bigint :sidekick2_id
      t.bigint :sidekick3_id
      t.bigint :sidekick4_id

      t.timestamps

      # 添加索引
      t.index [:sidekick1_id], name: 'battle_formation_sidekicks1_id_fk'
      t.index [:sidekick2_id], name: 'battle_formation_sidekicks2_id_fk'
      t.index [:sidekick3_id], name: 'battle_formation_sidekicks3_id_fk'
      t.index [:sidekick4_id], name: 'battle_formation_sidekicks4_id_fk'
      t.index [:player_id], name: 'battle_formations_players_id_fk'

      # 添加外键约束
    end
    add_foreign_key :battle_formations, :players, column: :player_id
    add_foreign_key :battle_formations, :sidekicks, column: :sidekick1_id
    add_foreign_key :battle_formations, :sidekicks, column: :sidekick2_id
    add_foreign_key :battle_formations, :sidekicks, column: :sidekick3_id
    add_foreign_key :battle_formations, :sidekicks, column: :sidekick4_id
  end
end
