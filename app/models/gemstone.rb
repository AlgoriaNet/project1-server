# frozen_string_literal: true

class Gemstone < ApplicationRecord
  UPGRADE_QUANTITY_COUNT = 5
  MAX_LEVEL = 7
  MIN_LEVEL = 1

  belongs_to :player, class_name: 'Player', foreign_key: :player_id
  belongs_to :gemstone_entry, class_name: 'GemstoneEntry', foreign_key: :entry_id
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
    self.entry_id = GemstoneEntry.where("level_#{self.level}_value > 0").sample.try(:id)
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
      map[entry_name][:value] += gemstone.gemstone_entry["level_#{gemstone.level}_value"]
    end
    map.values
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
    value = gemstone_entry["level_#{level}_value"]
    return gemstone_entry.effect_description if value.nil?
    
    case gemstone_entry.effect_name
    when 'Hp' then "Increases maximum health points by #{value.to_i}"
    when 'SufferedDamage' then "Reduces incoming damage by #{value}%"
    when 'Atk' then "Increases attack damage by #{value.to_i}"
    when 'Ctr' then "Increases critical hit rate by #{value}%"
    when 'Cti' then "Increases critical hit damage by #{value}%"
    when 'Mechanical' then "Adds mechanical damage to attacks by #{value}%"
    when 'Light' then "Adds light damage to attacks by #{value}%"
    when 'Fire' then "Adds fire damage to attacks by #{value}%"
    when 'Ice' then "Adds ice damage to attacks by #{value}%"
    when 'Wind' then "Adds wind damage to attacks by #{value}%"
    when 'Physics' then "Adds physical damage to attacks by #{value}%"
    when 'Darkly' then "Adds dark damage to attacks by #{value}%"
    when 'Heal' then "Increases healing effectiveness by #{value}%"
    when 'Damage' then "Increases overall damage output by #{value}%"
    when 'Cd' then "Reduces skill cooldown time by #{value}%"
    when 'Penetrat' then "Increases armor penetration by #{value}%"
    else
      gemstone_entry.effect_description
    end
  end

  def as_ws_json(options = nil)
    {
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
      entry_value: gemstone_entry["level_#{level}_value"]
    }
  end
end
