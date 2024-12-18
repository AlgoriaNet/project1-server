class Player < ApplicationRecord
  has_one :user
  has_one :hero

  has_many :sidekicks
  has_many :equipments
  has_many :battle_formations
end
