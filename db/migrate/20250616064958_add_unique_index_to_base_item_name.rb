class AddUniqueIndexToBaseItemName < ActiveRecord::Migration[7.1]
  def change
    # 先添加普通索引提高查询性能（如果尚未存在）
    add_index :base_items, :name unless index_exists?(:base_items, :name)

    # 添加唯一索引
    add_index :base_items, :name, unique: true, name: 'index_base_items_on_unique_name'
  end

end
