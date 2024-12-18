# frozen_string_literal: true

class BaseEquipment < ApplicationRecord
  enum quality: { common: :Common, pare: :Rare, fine: :Fine, epic: :Epic, legendary: :Legendary, mythic: :Mythic }
  enum part: { hat: :Hat, armor: :Armor, wristbands: :Wristbands, gloves: :Gloves, pants: :Pants, shoes: :Shoes }
end
