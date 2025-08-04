class Equipment < ApplicationRecord
  self.table_name = 'equipments'
  MAX_INLAY_GEMSTONE_COUNT = 6
  # OBSOLETE: Old fixed-count washing system
  WASHING_CONFIG = CsvConfig.load_washing_config.reduce({}) { |v, o| v[o[:level]] = o; v }
  
  # NEW: Probability-based washing system
  WASHING_PROBABILITY_CONFIG = CsvConfig.load_washing_probability_config.reduce({}) { |v, o| v[o[:quality]] = o; v }
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
    e = Equipment.new(base_equipment_id: base_id, player_id: player_id, intensify_level: 1)
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

  # Enhancement system constants
  MAX_ENHANCEMENT_LEVEL = 12
  MIN_ENHANCEMENT_LEVEL = 1  # Equipment starts at level 1
  
  # Enhancement attack bonus per quality level
  ENHANCEMENT_ATTACK_BONUS = {
    1 => 5,   # Quality 1: +5 attack per enhancement
    2 => 5,   # Quality 2: +5 attack per enhancement  
    3 => 5,   # Quality 3: +5 attack per enhancement
    4 => 10,  # Quality 4: +10 attack per enhancement
    5 => 10,  # Quality 5: +10 attack per enhancement
    6 => 15   # Quality 6: +15 attack per enhancement
  }.freeze

  # Calculate enhancement cost for upgrading from current level
  def self.enhancement_cost(from_level)
    return nil if from_level < MIN_ENHANCEMENT_LEVEL || from_level >= MAX_ENHANCEMENT_LEVEL
    
    # Cost calculation: Level 1→2 uses index 0, Level 2→3 uses index 1, etc.
    cost_index = from_level - 1
    crystal_cost = 100 + cost_index * 30 + cost_index ** 2 * 5
    gold_cost = (1500 * (1.4 ** cost_index)).round
    
    { crystals: crystal_cost, gold: gold_cost }
  end
  
  # Get enhancement cost for this equipment's next level
  def enhancement_cost
    Equipment.enhancement_cost(self.intensify_level)
  end
  
  # Calculate total attack bonus from enhancement
  def enhancement_attack_bonus
    return 0 if intensify_level < MIN_ENHANCEMENT_LEVEL
    
    quality = self.base_equipment.quality
    bonus_per_level = ENHANCEMENT_ATTACK_BONUS[quality] || 5
    (intensify_level - MIN_ENHANCEMENT_LEVEL) * bonus_per_level  # Level 1 = 0 bonus, Level 2 = 1 bonus, etc.
  end
  
  # Calculate total attack including base + enhancement
  def total_attack
    base_attack = self.base_equipment.base_atk
    enhancement_bonus = enhancement_attack_bonus
    base_attack + enhancement_bonus
  end
  
  # Get enhancement preview for UI display
  def enhancement_preview
    return nil unless can_enhance?
    
    current_attack = total_attack
    cost = enhancement_cost
    
    # Calculate next level attack
    quality = self.base_equipment.quality
    bonus_per_level = ENHANCEMENT_ATTACK_BONUS[quality] || 5
    next_attack = current_attack + bonus_per_level
    
    {
      current_level: intensify_level,
      next_level: intensify_level + 1,
      current_attack: current_attack,
      next_attack: next_attack,
      attack_increase: bonus_per_level,
      cost: cost
    }
  end
  
  # Check if equipment can be enhanced
  def can_enhance?
    intensify_level < MAX_ENHANCEMENT_LEVEL
  end

  # 强化 (Enhancement)
  def intensify
    unless can_enhance?
      return {
        success: false,
        error: "Equipment is already at maximum enhancement level (#{MAX_ENHANCEMENT_LEVEL})",
        current_level: intensify_level
      }
    end
    
    cost = enhancement_cost
    unless cost
      return {
        success: false,
        error: "Invalid enhancement level",
        current_level: intensify_level
      }
    end
    
    # Check if player has enough resources
    current_crystals = player.items_json["crystal"] || 0
    current_gold = player.gold_coin || 0
    
    if current_crystals < cost[:crystals] || current_gold < cost[:gold]
      return {
        success: false,
        error: "Insufficient resources",
        required: cost,
        current: { crystals: current_crystals, gold: current_gold },
        current_level: intensify_level
      }
    end
    
    ApplicationRecord.transaction do
      # Deduct resources
      player.remove_item!("crystal", cost[:crystals], "equipment_enhancement")
      player.gold_coin -= cost[:gold]
      player.save!
      
      # Increase enhancement level
      old_level = intensify_level
      self.intensify_level += 1
      self.total_crystals_spent += cost[:crystals]
      self.save!
      
      {
        success: true,
        old_level: old_level,
        new_level: intensify_level,
        cost_paid: cost,
        attack_bonus: enhancement_attack_bonus,
        total_attack: total_attack
      }
    end
  rescue => e
    {
      success: false,
      error: e.message,
      current_level: intensify_level
    }
  end

  # 自动强化 (Auto Enhancement)
  def auto_intensify(target_level = nil)
    target_level ||= MAX_ENHANCEMENT_LEVEL
    target_level = [target_level, MAX_ENHANCEMENT_LEVEL].min
    
    results = []
    total_crystals = 0
    total_gold = 0
    
    ApplicationRecord.transaction do
      while intensify_level < target_level
        result = intensify
        
        unless result[:success]
          # Stop auto enhancement on failure
          break
        end
        
        results << result
        total_crystals += result[:cost_paid][:crystals]
        total_gold += result[:cost_paid][:gold]
      end
    end
    
    {
      success: results.any?,
      enhancements_performed: results.size,
      final_level: intensify_level,
      total_cost: { crystals: total_crystals, gold: total_gold },
      details: results
    }
  end

  # 升品
  def upgrade_quality
    # todo
  end

  # 洗练 - New probability-based washing system
  def washing
    washing_config = WASHING_PROBABILITY_CONFIG[self.base_equipment.quality]
    return false unless washing_config
    
    # Determine number of attributes using probability
    rand_value = rand()
    attribute_count = if rand_value < washing_config[:prob_1_attr]
                        1
                      elsif rand_value < washing_config[:prob_1_attr] + washing_config[:prob_2_attr]
                        2
                      else
                        3
                      end
    
    # Generate random attributes
    nearby_attr = {}
    available_entries = (self.base_equipment.quality >= 6 ? WASHING_TOP_ENTRIES : WASHING_ENTRIES).dup
    
    attribute_count.times do
      break if available_entries.empty?
      
      # Pick random entry and remove it to avoid duplicates
      entry = available_entries.sample
      available_entries.delete(entry)
      
      # Generate random value within range
      value = rand(washing_config[:min_value]..washing_config[:max_value])
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
