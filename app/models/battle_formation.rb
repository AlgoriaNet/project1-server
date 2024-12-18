# frozen_string_literal: true
# 阵容编队
# 一个玩家容许最多有3套编队
class BattleFormation < ActiveRecord::Base
  belongs_to :player, class_name: 'Player', foreign_key: :player_id

  belongs_to :sidekick1, class_name: 'Sidekick', foreign_key: :sidekick1_id
  belongs_to :sidekick2, class_name: 'Sidekick', foreign_key: :sidekick2_id
  belongs_to :sidekick3, class_name: 'Sidekick', foreign_key: :sidekick3_id
  belongs_to :sidekick4, class_name: 'Sidekick', foreign_key: :sidekick4_id
end
