# frozen_string_literal: true

class Gemstone < ApplicationRecord
  UPGRADE_QUANTITY_COUNT = 5
  MAX_LEVEL = 7
  MIN_LEVEL = 1

  belongs_to :player, class_name: 'Player', foreign_key: :player_id
  belongs_to :gemstone_entry, class_name: 'GemstoneEntry', foreign_key: :entry_id
  belongs_to :secondary_gemstone_entry, class_name: 'GemstoneEntry', foreign_key: :secondary_entry_id, optional: true
  belongs_to :equipment, optional: true, foreign_key: :equipment_id
  
  # Legacy associations - keep for migration compatibility
  belongs_to :sidekick, optional: true, class_name: 'Sidekick', foreign_key: :inlay_with_sidekick_id
  belongs_to :hero, optional: true, class_name: 'Hero', foreign_key: :inlay_with_hero_id

  def self.generate(level, player_id)
    new = Gemstone.new
    new.level = level
    new.player_id = player_id
    new.random_entry
    new.part = BaseEquipment::PARTS.sample
    new.is_locked = false
    new
  end

  def random_entry
    # New system: Levels 1-4 get basic attributes (1-11), Levels 5-7 get dual attributes (1-22)
    if self.level <= 4
      # Single attribute from basic attributes (attribute_id 1-11)
      basic_entries = GemstoneEntry.where(attribute_type: 'basic')
      self.entry_id = basic_entries.sample.try(:id) if basic_entries.any?
      self[:secondary_entry_id] = nil # Clear secondary for single attribute gems
    else
      # Dual attributes from all attributes (1-22) - pick two different ones
      all_entries = GemstoneEntry.all.to_a
      if all_entries.size >= 2
        selected_entries = all_entries.sample(2)
        self.entry_id = selected_entries[0].id
        self[:secondary_entry_id] = selected_entries[1].id
      else
        # Fallback if not enough entries
        self.entry_id = all_entries.sample.try(:id) if all_entries.any?
        self[:secondary_entry_id] = nil
      end
    end
    self
  end

  def lock
    self.is_locked = true
    self
  end

  def unlock
    self.is_locked = false
    self
  end

  # New equipment-based inlay method
  def inlay_with_equipment(equipment, slot_number = 1)
    return { success: false, error: "Gem is already embedded" } if is_embedded?
    return { success: false, error: "Invalid slot number" } unless (1..5).include?(slot_number)
    return { success: false, error: "Part mismatch" } unless equipment.base_equipment.part == self.part
    
    # Check if slot is already occupied
    existing_gem = Gemstone.find_by(equipment_id: equipment.id, slot_number: slot_number)
    if existing_gem
      return { success: false, error: "Slot #{slot_number} is already occupied" }
    end
    
    ApplicationRecord.transaction do
      self.equipment_id = equipment.id
      self.slot_number = slot_number
      self.is_in_inventory = false
      self.save!
    end
    
    { success: true }
  end
  
  # Legacy method - keep for backward compatibility
  def inlay_with(living)
    # 如果该装备已经装备了，就不能再装备
    return false if is_inlaid?
    # 如果该装备的部位已经装备了其他装备, 先卸下
    puts "living: #{living.id}, equipments_count: #{living.equipments.count}"
    inlaid = living.gemstones.reload.to_a.select do |gemstone|
      gemstone.part == self.part && gemstone.entry_id == self.entry_id
    end
    inlaid.each(&:outlay)

    if living.class == Hero
      self.inlay_with_hero_id = living.id
    elsif living.class == Sidekick
      self.inlay_with_sidekick_id = living.id
    else
      return false
    end
    self.save!
    true
  end

  # New equipment-based outlay method
  def outlay_from_equipment
    return { success: false, error: "Gem is not embedded" } unless is_embedded?
    
    ApplicationRecord.transaction do
      self.equipment_id = nil
      self.slot_number = 1
      self.is_in_inventory = true
      self.save!
    end
    
    { success: true }
  end
  
  # Legacy outlay method
  def outlay
    self.inlay_with_hero_id = nil
    self.inlay_with_sidekick_id = nil
    self.save!
  end

  # New equipment-based embedding status
  def is_embedded?
    self.equipment_id.present?
  end
  
  # Legacy method
  def is_inlaid?
    self.inlay_with_hero_id.present? || self.inlay_with_sidekick_id.present?
  end

  # 一键升级
  def self.auto_upgrade(player_id)
    (MIN_LEVEL...MAX_LEVEL).each do |level|
      unlocked_gems = where(player_id: player_id, level: level, is_locked: false)
      while unlocked_gems.count >= UPGRADE_QUANTITY_COUNT
        gems_to_upgrade = unlocked_gems.limit(UPGRADE_QUANTITY_COUNT).to_a
        upgrade(player_id, gems_to_upgrade.map(&:id))
        unlocked_gems = where(player_id: player_id, level: level, is_locked: false)
      end
    end
  end

  # 升级
  def self.upgrade(player_id, gemstone_ids)
    validate_upgrade = validate_upgrade(player_id, gemstone_ids)
    if validate_upgrade
      gemstones = Gemstone.where(player_id: player_id, id: gemstone_ids).to_a
      gemstones.each { |g| g.destroy }
      new_gemstone = Gemstone.new(level: gemstones.first.level + 1, player_id: player_id).save!
    else
      false
    end
  end

  # Auto merge gemstones based on filters
  def self.auto_merge(player_id, options = {})
    target_parts = options[:target_parts] || BaseEquipment::PARTS
    max_level = options[:max_level] || (MAX_LEVEL - 1) # Don't merge max level gems
    
    result = {
      success: true,
      merged_groups: [],
      total_operations: 0,
      total_gems_consumed: 0,
      total_gems_created: 0
    }
    
    ApplicationRecord.transaction do
      # Get unembedded inventory gems
      available_gems = Gemstone.where(
        player_id: player_id,
        is_in_inventory: true,
        equipment_id: nil,
        part: target_parts,
        level: MIN_LEVEL..max_level
      ).group_by { |gem| [gem.part, gem.level] }
      
      available_gems.each do |(part, level), gems|
        merge_count = gems.count / UPGRADE_QUANTITY_COUNT
        next if merge_count == 0 # Need at least 5 gems
        
        merge_count.times do
          # Take exactly 5 gems for each merge
          gems_to_merge = gems.shift(UPGRADE_QUANTITY_COUNT)
          
          # Remove old gems
          gems_to_merge.each(&:destroy)
          
          # Create new gem with higher level
          new_gem = Gemstone.generate(level + 1, player_id)
          new_gem.part = part
          new_gem.save!
          
          # Track operation
          result[:merged_groups] << {
            part: part,
            from_level: level,
            to_level: level + 1,
            gems_consumed: UPGRADE_QUANTITY_COUNT,
            gems_created: 1,
            new_gem: new_gem.as_ws_json
          }
          
          result[:total_operations] += 1
          result[:total_gems_consumed] += UPGRADE_QUANTITY_COUNT
          result[:total_gems_created] += 1
        end
      end
    end
    
    result
  rescue => e
    {
      success: false,
      error: e.message,
      merged_groups: [],
      total_operations: 0,
      total_gems_consumed: 0,
      total_gems_created: 0
    }
  end

  # 验证升级
  def self.validate_upgrade(player_id, gemstone_ids)
    return false if gemstone_ids.size != UPGRADE_QUANTITY_COUNT
    gemstones = Gemstone.where(player_id: player_id, id: gemstone_ids)
    return false if gemstones.size != UPGRADE_QUANTITY_COUNT
    return false if gemstones.map(&:level).uniq.size != 1
    return false if gemstones.select { |g| g.is_look }.present?
    true
  end

  def self.get_gemstone_entries_summary(gemstones)
    map = {}
    gemstones.each do |gemstone|
      entry_name = gemstone.gemstone_entry.effect_name
      description = gemstone.gemstone_entry.effect_description
      map[entry_name] ||= { name: entry_name, description: description, value: 0 }
      map[entry_name][:value] += gemstone.calculated_primary_value
    end
    map.values
  end
  
  # Auto embed gemstones into equipment slots
  def self.auto_embed(player_id, equipment_id)
    player = Player.find(player_id)
    equipment = player.equipments.find(equipment_id)
    
    result = {
      success: true,
      operations: [],
      total_embedded: 0
    }
    
    ApplicationRecord.transaction do
      # Get available gems in inventory
      available_gems = player.gemstones.where(
        is_in_inventory: true,
        equipment_id: nil
      )
      
      # Process each slot (1-5)
      (1..5).each do |slot_number|
        current_gem = equipment.gemstones.find_by(slot_number: slot_number)
        
        if current_gem.nil?
          # Empty slot - find best gem for this part
          best_gem = choose_gem_for_empty_slot(equipment.base_equipment.part, available_gems)
          
          if best_gem
            embed_result = best_gem.inlay_with_equipment(equipment, slot_number)
            if embed_result[:success]
              available_gems = available_gems.where.not(id: best_gem.id) # Remove from available
              result[:operations] << {
                action: "embed",
                slot: slot_number,
                gem: best_gem.as_ws_json
              }
              result[:total_embedded] += 1
            end
          end
        else
          # Occupied slot - find replacement gem
          replacement_gem = find_replacement_gem(current_gem, available_gems)
          
          if replacement_gem
            # Remove current gem
            current_gem.outlay_from_equipment
            
            # Embed replacement
            embed_result = replacement_gem.inlay_with_equipment(equipment, slot_number)
            if embed_result[:success]
              available_gems = available_gems.where.not(id: replacement_gem.id) # Remove from available
              result[:operations] << {
                action: "replace",
                slot: slot_number,
                old_gem: current_gem.as_ws_json,
                new_gem: replacement_gem.as_ws_json
              }
              result[:total_embedded] += 1
            end
          end
        end
      end
    end
    
    result
  rescue => e
    {
      success: false,
      error: e.message,
      operations: [],
      total_embedded: 0
    }
  end
  
  # Choose gem for empty slot: highest level, break ties with lowest attribute_id
  def self.choose_gem_for_empty_slot(part, available_gems)
    part_gems = available_gems.select { |g| g.part == part }
    return nil if part_gems.empty?
    
    # Step 1: Find highest level available
    max_level = part_gems.map(&:level).max
    highest_level_gems = part_gems.select { |g| g.level == max_level }
    
    # Step 2: If multiple at max level, pick lowest attribute_id
    highest_level_gems.min_by { |gem| gem.gemstone_entry.attribute_id }
  end
  
  # Find replacement gem: same part, same attribute, higher level
  def self.find_replacement_gem(current_gem, available_gems)
    candidates = available_gems.select do |gem|
      gem.part == current_gem.part &&
      gem.gemstone_entry.attribute_id == current_gem.gemstone_entry.attribute_id &&
      gem.level > current_gem.level
    end
    
    # Pick highest level of same attribute type
    candidates.max_by(&:level)
  end

  def level_name
    case level
    when 1 then "Basic Gem"
    when 2 then "Prime Gem"
    when 3 then "Rare Gem"
    when 4 then "Epic Gem"
    when 5 then "Legendary Gem"
    when 6 then "Mythic Gem"
    when 7 then "Ultimate Gem"
    end
  end

  def dynamic_effect_description
    descriptions = []
    
    # Primary attribute
    primary_value = calculated_primary_value
    descriptions << build_effect_description(gemstone_entry, primary_value)
    
    # Secondary attribute (for levels 5-7)
    if has_dual_attributes? && secondary_gemstone_entry
      secondary_value = calculated_secondary_value
      descriptions << build_effect_description(secondary_gemstone_entry, secondary_value)
    end
    
    descriptions.join("\n")
  end
  
  # Level multipliers for professional progression
  LEVEL_MULTIPLIERS = [1.0, 1.5, 2.0, 2.5, 3.5, 4.5, 6.0].freeze
  
  def calculated_primary_value
    return 0 unless gemstone_entry&.base_value
    base_value = gemstone_entry.base_value
    multiplier = LEVEL_MULTIPLIERS[level - 1] || 1.0
    calculated_value = base_value * multiplier
    has_dual_attributes? ? (calculated_value * 0.75) : calculated_value
  end
  
  def calculated_secondary_value
    return 0 unless secondary_gemstone_entry&.base_value
    base_value = secondary_gemstone_entry.base_value
    multiplier = LEVEL_MULTIPLIERS[level - 1] || 1.0
    (base_value * multiplier) * 0.75
  end
  
  def has_dual_attributes?
    level >= 5
  end
  
  def build_effect_description(entry, value)
    return entry.effect_description if value.nil? || value == 0
    
    # Use the updated UI-friendly description with formatted value
    formatted_value = format_attribute_value(entry, value)
    "#{entry.effect_description} +#{formatted_value}"
  end
  
  def format_attribute_value(entry, value)
    case entry.effect_name
    when 'Hp', 'Atk', 'Kill Heal', 'Auto Strike', 'Crisis Regen', 'Kill Gold'
      # Flat values (no percentage) - always show as integers
      value.round.to_s
    when 'Invincibility'
      # Duration in seconds
      value % 1 == 0 ? "#{value.to_i}s" : "#{value.round(1)}s"
    when 'Ctr', 'Cti', 'Mechanical', 'Light', 'Fire', 'Ice', 'Wind', 'Physics', 'Darkly', 
         'Elite Heal', 'Low HP Boost', 'Close Range', 'Damage Reduction', 'Elite Boost', 'High HP Damage'
      # Percentage values - clean formatting
      if value % 1 == 0
        "#{value.to_i}%"
      elsif (value * 10) % 1 == 0  # e.g., 337.5 -> show as 337.5%
        "#{value.round(1)}%"
      else
        "#{value.round}%"  # Round to nearest integer for complex decimals
      end
    else
      # Default: clean number formatting
      value % 1 == 0 ? value.to_i.to_s : value.round(1).to_s
    end
  end

  def as_ws_json(options = nil)
    result = {
      id: id,
      effect_name: gemstone_entry.effect_name,
      effect_description: dynamic_effect_description,
      part: part,
      level: level,
      level_name: level_name,
      is_locked: is_locked,
      # New equipment-based fields
      equipment_id: equipment_id,
      slot_number: slot_number,
      is_in_inventory: is_in_inventory,
      is_embedded: is_embedded?,
      # Legacy fields for backward compatibility
      inlay_with_hero_id: inlay_with_hero_id,
      inlay_with_sidekick_id: inlay_with_sidekick_id,
      entry_id: entry_id,
      entry_value: calculated_primary_value,
      # New dual attribute fields
      has_dual_attributes: has_dual_attributes?,
      primary_attribute: {
        name: gemstone_entry.effect_name,
        value: calculated_primary_value,
        attribute_id: gemstone_entry.attribute_id
      }
    }
    
    # Add secondary attribute info for dual attribute gems
    if has_dual_attributes? && secondary_gemstone_entry
      result[:secondary_attribute] = {
        name: secondary_gemstone_entry.effect_name,
        value: calculated_secondary_value,
        attribute_id: secondary_gemstone_entry.attribute_id
      }
      result[:secondary_entry_id] = secondary_entry_id
    end
    
    result
  end
end
