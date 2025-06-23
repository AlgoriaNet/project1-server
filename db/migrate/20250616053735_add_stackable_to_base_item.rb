class AddStackableToBaseItem < ActiveRecord::Migration[7.1]
  def change
    add_column :base_items, :stackable, :boolean, default: true, null: false
  end
end
