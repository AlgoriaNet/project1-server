class Player < ApplicationRecord
  belongs_to :deployed_sidekick1, foreign_key: 'deployed_sidekick1_id', class_name: 'Sidekick'
  belongs_to :deployed_sidekick2, foreign_key: 'deployed_sidekick2_id', class_name: 'Sidekick'
  belongs_to :deployed_sidekick3, foreign_key: 'deployed_sidekick3_id', class_name: 'Sidekick'
  belongs_to :deployed_sidekick4, foreign_key: 'deployed_sidekick4_id', class_name: 'Sidekick'
  has_one :user
  has_one :hero
  has_many :sidekicks
end
