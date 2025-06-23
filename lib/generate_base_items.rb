class GenerateBaseItems
  def self.generate
    BaseItem.destroy_all
    CsvConfig.load_base_items.each do |base_equipment|
      BaseItem.create(base_equipment)
    end
  end
end
