class AddEquipmentSlotsToGemstones < ActiveRecord::Migration[7.1]
  def change
    # Add new equipment-based embedding columns
    add_column :gemstones, :equipment_id, :bigint
    add_column :gemstones, :slot_number, :integer, default: 1
    add_column :gemstones, :is_in_inventory, :boolean, default: true
    
    # Add foreign key constraint
    add_foreign_key :gemstones, :equipments, column: :equipment_id
    
    # Add index for performance
    add_index :gemstones, [:equipment_id, :slot_number], unique: true, where: 'equipment_id IS NOT NULL'
  end
  
  def down
    # Safe rollback
    remove_index :gemstones, [:equipment_id, :slot_number]
    remove_foreign_key :gemstones, :equipments
    remove_column :gemstones, :equipment_id
    remove_column :gemstones, :slot_number
    remove_column :gemstones, :is_in_inventory
  end
end
