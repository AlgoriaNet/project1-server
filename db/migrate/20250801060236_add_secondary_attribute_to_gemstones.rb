class AddSecondaryAttributeToGemstones < ActiveRecord::Migration[7.1]
  def change
    add_column :gemstones, :secondary_entry_id, :bigint
    add_foreign_key :gemstones, :gemstone_entries, column: :secondary_entry_id
  end
end
