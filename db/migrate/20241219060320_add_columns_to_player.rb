class AddColumnsToPlayer < ActiveRecord::Migration[7.1]
  def change
    add_column :players, :unpack_counts, :text
  end
end
