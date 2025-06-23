class AddTypeToBaseItem < ActiveRecord::Migration[7.1]
  def change
    add_column :base_items, :item_type, :string
  end
end
