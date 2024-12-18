class Player < ApplicationRecord
  has_one :user
  has_one :hero

  has_many :sidekicks
  has_many :equipments
  has_many :battle_formations

  def get_gemstone_entries_summary
    Gemstone.get_gemstone_entries_summary(self.equipments.map(&:gemstones).flatten)
  end
end
