class CreateGemstoneEntries < ActiveRecord::Migration[7.1]
  def change
    create_table :gemstone_entries do |t|
      t.string :description
      t.string :name
      t.float :level_1_value
      t.float :level_2_value
      t.float :level_3_value
      t.float :level_4_value
      t.float :level_5_value
      t.float :level_6_value
      t.float :level_7_value
      t.float :level_8_value
      t.float :level_9_value
      t.float :level_10_value
      t.timestamps
    end
  end
end
