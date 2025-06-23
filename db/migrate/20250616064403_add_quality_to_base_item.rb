class AddQualityToBaseItem < ActiveRecord::Migration[7.1]
  def change
    add_column :base_items, :quality, :integer
  end
end
