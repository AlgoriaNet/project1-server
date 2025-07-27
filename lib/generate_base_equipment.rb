class GenerateBaseEquipment
  def self.generate
    # Delete child equipment records first to avoid foreign key constraint violations
    Equipment.destroy_all
    BaseEquipment.destroy_all
    CsvConfig.load_base_equipment.each do |base_equipment|
      # Remove the id field from CSV data since it conflicts with auto-increment primary key
      equipment_data = base_equipment.except(:id)
      BaseEquipment.create(equipment_data)
    end
  end


  def self.gm(count)
    base_equipments = BaseEquipment.all
    (1..count).each do |i|
      Equipment.init(base_equipments.sample.id, 1)
    end
  end
end

