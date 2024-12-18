class CreateBaseSidekicks < ActiveRecord::Migration[7.1]
  def change
    create_table :base_sidekicks do |t|
      t.string :name, null: false, limit: 255
      t.text :description
      t.integer :skill_id, null: false, comment: "Base技能"
      t.text :character, null: false, comment: "特性"
      t.integer :atk, null: false, default: 0, comment: '基础攻击力'
      t.integer :def, null: false, default: 0, comment: '基础防御力'
      t.integer :cri, null: false, default: 0, comment: '暴击力'
      t.integer :crt, null: false, default: 150, comment: '暴击伤害'
      t.json :variety_damage, null: false

      t.timestamps
    end
  end
end
