class GenerateBaseEquipment
  def self.generate
    BaseEquipment.destroy_all
    CscConfig.load_base_equipment.each do |base_equipment|
      BaseEquipment.create(base_equipment)
    end
  end


  def self.gm(count)
    base_equipments = BaseEquipment.all
    (1..count).each do |i|
      Equipment.init(base_equipments.sample.id, 1)
    end
  end
end

