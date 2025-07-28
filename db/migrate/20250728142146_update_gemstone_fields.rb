class UpdateGemstoneFields < ActiveRecord::Migration[7.1]
  def change
    # Rename GemstoneEntry fields for clarity
    rename_column :gemstone_entries, :name, :effect_name
    rename_column :gemstone_entries, :description, :effect_description
    
    # Remove unused quality field from Gemstone (only 2 out of 664 gems used it)
    remove_column :gemstones, :quality, :integer
  end
end
