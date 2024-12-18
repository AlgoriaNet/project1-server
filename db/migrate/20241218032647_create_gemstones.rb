class CreateGemstones < ActiveRecord::Migration[7.1]
  def change
    create_table :gemstones do |t|
      t.string :name
      t.string :description
      t.string :level
      t.string :quality
      t.bigint :entry_id
      t.string :access_channels
      t.bigint :player_id
      t.bigint :equip_id
      t.boolean :is_locked, default: false
      t.timestamps
    end

    add_foreign_key :gemstones, :gemstone_entries, column: :entry_id
    add_foreign_key :gemstones, :players, column: :player_id
    add_foreign_key :gemstones, :equipments, column: :equip_id
  end
end
