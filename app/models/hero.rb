class Hero < Living
  belongs_to :player, foreign_key: 'player_id', class_name: 'Player'

  has_many :equipments, foreign_key: 'equip_with_hero_id', class_name: 'Equipment'
  has_many :gemstones, foreign_key: 'inlay_with_hero_id', class_name: 'Gemstone'
end
