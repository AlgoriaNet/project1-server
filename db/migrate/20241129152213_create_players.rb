class CreatePlayers < ActiveRecord::Migration[7.1]
  def change
    create_table :players do |t|
      t.string :name, comment: '用户昵称'
      t.integer :level, default: 1, comment: '等级', null: false
      t.integer :exp, default: 0, comment: '经验', null: false
      t.integer :gold_coin, default: 0, comment: '金币', null: false
      t.integer :diamond, default: 0, comment: '钻石', null: false
      t.integer :stamina, default: 100, comment: '体力', null: false
      t.timestamps
    end
  end
end
