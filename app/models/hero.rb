class Hero < Living
  belongs_to :player, foreign_key: 'player_id', class_name: 'Player'
end
