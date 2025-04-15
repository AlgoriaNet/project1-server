# frozen_string_literal: true

class Gemstone < ApplicationRecord
  UPGRADE_QUANTITY_COUNT = 5
  MAX_LEVEL = 7
  MIN_LEVEL = 1

  belongs_to :player, class_name: 'Player', foreign_key: :player_id
  belongs_to :gemstone_entry, class_name: 'GemstoneEntry', foreign_key: :entry_id
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

  def outlay
    self.inlay_with_hero_id = nil
    self.inlay_with_sidekick_id = nil
    self.save!
  end

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
      entry_name = gemstone.gemstone_entry.name
      description = gemstone.gemstone_entry.description
      map[entry_name] ||= { name: entry_name, description: description, value: 0 }
      map[entry_name][:value] += gemstone.gemstone_entry["level_#{gemstone.level}_value"]
    end
    map.values
  end

  def as_ws_json(options = nil)
    {
      id: id,
      name: gemstone_entry.name,
      description: gemstone_entry.description,
      part: part,
      level: level,
      quality: quality,
      is_locked: is_locked,
      inlay_with_hero_id: inlay_with_hero_id,
      inlay_with_sidekick_id: inlay_with_sidekick_id,
      entry_id: entry_id,
      entry_value: gemstone_entry["level_#{level}_value"]
    }
  end
end
