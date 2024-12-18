# frozen_string_literal: true

class Equipment < ApplicationRecord
  MAX_INLAY_GEMSTONE_COUNT = 6

  belongs_to :base_equipment, class_name: 'BaseEquipment', foreign_key: :base_equipment_id
  belongs_to :sidekick, class_name: 'Sidekick', foreign_key: :equip_with_sidekick_id
  belongs_to :hero, class_name: 'Hero', foreign_key: :equip_with_hero_id
  belongs_to :player, class_name: 'Player', foreign_key: :player_id

  has_many :gemstones, class_name: 'Gemstone'

  def initialize(base_id, player_id)
    e = Equipment.new(base_id: base_id, player_id: player)
    e.washing
    e.save!
  end

  def get_gemstone_entries_summary
    Gemstone.get_gemstone_entries_summary(self.gemstones)
  end

  #装备
  def equip_with(living)
    return false if is_equipped?
    equipped = living.equipments.find{|equip| equip.base_equipment.part != self.base_equipment.part}
    if living.class == Hero
      equipped.unequip
      self.equip_with_hero_id = living.id
    elsif living.class == Sidekick
      equipped.unequip
      self.equip_with_sidekick_id = living.id
    else
      return false
    end
    true
  end

  #卸下
  def unequip
    self.equip_with_hero_id = nil;
    self.equip_with_sidekick_id = nil;
  end

  #强化
  def intensify
    # todo
  end

  #自动强化
  def auto_intensify
    # todo
  end

  #升品
  def upgrade_quality
    # todo
  end

  #洗练
  def washing
    # todo
  end

  # 镶嵌宝石
  def inlay(gemstone_id)
    gemstone = self.gemstones.find(gemstone_id)
    gemstone.inlay(self.id)
  end

  # 拆卸宝石
  def outlay(gemstone_id)
    gemstone = self.gemstones.find(gemstone_id)
    gemstone.outlay
  end

  # 自动镶嵌宝石
  def auto_inlay
    inlaid = self.gemstones.map(&:gemstone_entry)
    (inlaid.size...MAX_INLAY_GEMSTONE_COUNT).each do |_|
      gemstone = Gemstone.where(player_id: self.player_id, equip_id: nil)
                         .where.not(gemstone_entry: inlaid)
                         .order("level desc").first
      gemstone.inlay(self.id) if gemstone.present?
      inlaid << gemstone.gemstone_entry
    end
  end

  # 自动拆卸宝石
  def auto_outlay
    self.gemstones.each do |gemstone|
      gemstone.outlay
    end
  end

  def is_equipped?
    self.equip_with_hero_id.present? || self.equip_with_sidekick_id.present?
  end

  def self.get_not_equipped
    where(equip_with_hero_id: nil).where(equip_with_sidekick_id: nil).all
  end
end
