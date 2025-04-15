class ChangeGemstones < ActiveRecord::Migration[7.1]
  def change
    change_column :gemstones, :quality, :integer, null: true
    add_column :gemstones, :inlay_with_sidekick_id, :int, null: true
    add_column :gemstones, :inlay_with_hero_id, :int, null: true
    add_column :gemstones, :part, :string, null: false
    remove_column :gemstones, :equip_id, :string
  end
end
