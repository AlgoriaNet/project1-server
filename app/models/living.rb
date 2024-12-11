# frozen_string_literal: true

class Living < ActiveRecord::Base
  self.abstract_class = true
  include Redis::Objects
  value :MaxHp
  value :Hp
  value :Atk
  value :AtkBonus
  value :AtkBonusRate
  value :Def
  value :DefBonus
  value :DefBonusRate
  value :Speed
  value :SpeedBonus
  value :SpeedBonusRate
  value :CRI
  value :CRIBonus
  value :CRT
  value :CRTBonus
  value :DamageBonusRate
  value :SufferedDamageBonusRate
  hash_key :VarietyDamage
  hash_key :VarietyDamageBonus
  hash_key :VarietyDamageBonusRate
  hash_key :SufferedVarietyDamageBonusRate
end
