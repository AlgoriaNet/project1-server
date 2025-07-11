class Sidekick < ApplicationRecord
  belongs_to :base_sidekick, foreign_key: 'base_id', class_name: 'BaseSidekick'
  belongs_to :player, foreign_key: 'player_id', class_name: 'Player'

  has_many :equipments

  # 验证
  validates :base_id, presence: true
  validates :player_id, presence: true
  validates :skill_level, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :star, presence: true, numericality: { greater_than_or_equal_to: 0 }

  def as_ws_json(options = nil)
    super(options).merge({
      'base_sidekick' => base_sidekick.as_ws_json
    })
  end
end


