# frozen_string_literal: true

class Gemstone < ApplicationRecord
  UPGRADE_QUANTITY_COUNT = 5
  MAX_LEVEL = 7
  MIN_LEVEL = 1

  belongs_to :player, class_name: 'Player', foreign_key: :player_id
  belongs_to :gemstone_entry, class_name: 'GemstoneEntry', foreign_key: :entry_id
  belongs_to :equipment, class_name: 'Equipment', foreign_key: :equip_id

  def initialize(level, player_id)
    self.level = MIN_LEVEL if level < MIN_LEVEL
    self.level = MAX_LEVEL if level > MAX_LEVEL
    self.player_id = player_id
    random_entry
    self.is_locked = false
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

  def inlay(equip_id)
    # 如果已经镶嵌在了装备上，不能再镶嵌
    return false if self.equip_id.present?
    equipment = self.player.equipments.find(equip_id)

    # 如果装备不存在，不能镶嵌
    return false if equipment.blank?
    is_inlaid = equipment.gemstones.find { |g| g.gemstone_entry == self.gemstone_entry }.present?

    # 如果装备上已经有同类型的宝石，不能再镶嵌
    return false if is_inlaid
    self.equip_id = equip_id
    self.save!
  end

  def outlay
    return false if self.equip_id.blank?
    self.equip_id = nil
    self.save!
  end

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
      entry_name = gemstone.gemstone_entry.name
      description = gemstone.gemstone_entry.description
      map[entry_name] ||= { name: entry_name, description: description, value: 0 }
      map[entry_name][:value] += gemstone.gemstone_entry["level_#{gemstone.level}_value"]
    end
    map.values
  end
end
