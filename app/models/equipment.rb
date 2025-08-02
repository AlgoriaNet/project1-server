class Equipment < ApplicationRecord
  self.table_name = 'equipments'
  MAX_INLAY_GEMSTONE_COUNT = 6
  WASHING_CONFIG = CsvConfig.load_washing_config.reduce({}) { |v, o| v[o[:level]] = o; v }
  WASHING_ENTRIES = [:Mechanical,
                     :Light,
                     :Fire,
                     :Ice,
                     :Wind,
                     :Physics,
                     :Darkly,
                     :Cure,
                     :Burn]
  WASHING_TOP_ENTRIES = WASHING_ENTRIES + [:All]

  belongs_to :base_equipment, class_name: 'BaseEquipment', foreign_key: :base_equipment_id
  belongs_to :sidekick, optional: true, class_name: 'Sidekick', foreign_key: :equip_with_sidekick_id
  belongs_to :hero, optional: true, class_name: 'Hero', foreign_key: :equip_with_hero_id
  belongs_to :player, class_name: 'Player', foreign_key: :player_id

  has_many :gemstones, foreign_key: :equipment_id, dependent: :nullify
  serialize :nearby_attributes, type: Hash, coder: JSON

  def self.init(base_id, player_id)
    e = Equipment.new(base_equipment_id: base_id, player_id: player_id)
    e.washing
    e.save!
  end

  def get_gemstone_entries_summary
    Gemstone.get_gemstone_entries_summary(self.gemstones)
  end
  
  # New method for equipment-based gem embedding
  def get_embedded_gems_summary
    (1..5).map do |slot|
      gem = self.gemstones.find_by(slot_number: slot)
      {
        slot: slot,
        gem: gem&.as_ws_json,
        is_empty: gem.nil?
      }
    end
  end
  
  def embed_gem(gemstone, slot_number)
    gemstone.inlay_with_equipment(self, slot_number)
  end
  
  def remove_gem(slot_number)
    gem = self.gemstones.find_by(slot_number: slot_number)
    return { success: false, error: "No gem in slot #{slot_number}" } unless gem
    gem.outlay_from_equipment
  end

  # 装备
  def equip_with(living)
    # 如果该装备已经装备了，就不能再装备
    return false if is_equipped?
    # 如果该装备的部位已经装备了其他装备, 先卸下
    puts "living: #{living.id}, equipments_count: #{living.equipments.count}"
    equipped = living.equipments.reload.to_a.select { |equip| equip.base_equipment.part == self.base_equipment.part }
    equipped.each(&:unequip)
    if living.class == Hero
      self.equip_with_hero_id = living.id
    elsif living.class == Sidekick
      self.equip_with_sidekick_id = living.id
    else
      return false
    end
    self.save!
    true
  end

  # 卸下
  def unequip
    puts "unequip: #{self.id}"
    puts "equip_with_hero_id: #{self.equip_with_hero_id}"
    self.equip_with_hero_id = nil;
    self.equip_with_sidekick_id = nil;
    self.save!
  end

  # 强化
  def intensify

  end

  # 自动强化
  def auto_intensify
    # todo
  end

  # 升品
  def upgrade_quality
    # todo
  end

  # 洗练
  def washing
    washing_config = WASHING_CONFIG[self.base_equipment.quality]
    count = washing_config[:count]
    nearby_attr = {}
    (1..count).each do |i|
      entry = (self.base_equipment.quality >= 6? WASHING_TOP_ENTRIES : WASHING_ENTRIES).sample
      value = (washing_config[:min_value]..washing_config[:max_value]).to_a.sample
      nearby_attr[entry] = value
    end
    self.nearby_attributes = nearby_attr
    self.save!
  end

  # 分解装备 (只能分解背包中的备用装备)
  def dismantle
    # Check if equipment is equipped - equipped equipment cannot be dismantled
    if self.is_equipped?
      return {
        success: false,
        error: "Cannot dismantle equipped equipment. Only spare equipment in pack can be dismantled.",
        equipment_id: self.id
      }
    end
    
    # Calculate crystal reward
    base_crystals = 10
    refund_crystals = (self.total_crystals_spent * 0.8).to_i
    total_crystals = base_crystals + refund_crystals
    
    # Add crystals to player
    self.player.add_item!("crystal", total_crystals, "equipment_dismantle")
    
    # Delete the equipment
    result = {
      success: true,
      crystals_rewarded: total_crystals,
      base_crystals: base_crystals,
      refund_crystals: refund_crystals,
      equipment_id: self.id
    }
    
    self.destroy!
    result
  end

  def is_equipped?
    self.equip_with_hero_id.present? || self.equip_with_sidekick_id.present?
  end

  def self.get_not_equipped
    where(equip_with_hero_id: nil).where(equip_with_sidekick_id: nil).all
  end

  def as_ws_json
    return {
      id: self.id,
      intensify_level: self.intensify_level,
      nearby_attributes: self.nearby_attributes,
      additional_attributes: self.additional_attributes,
      equip_with_hero_id: self.equip_with_hero_id,
      equip_with_sidekick_id: self.equip_with_sidekick_id,
      total_crystals_spent: self.total_crystals_spent,
      embedded_gems: get_embedded_gems_summary
    }.merge(self.base_equipment.as_ws_json.symbolize_keys)
  end
end
