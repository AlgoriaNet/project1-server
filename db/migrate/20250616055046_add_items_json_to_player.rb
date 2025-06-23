class AddItemsJsonToPlayer < ActiveRecord::Migration[7.1]
  def change
    add_column :players, :items_json, :json
    # MySQL 8.0 的JSON索引 (针对特定路径查询优化)

    # # 通用JSON索引
    # add_index :players,
    #           "((items_json->>'$.weapons'))",
    #           name: 'index_players_on_weapons_items',
    #           length: 255,
    #           using: :btree
  end
end
