class FirstChargeClaim < ApplicationRecord
  # Associations
  belongs_to :player
  belongs_to :first_charge_tier_reward, query_constraints: [:tier, :day], optional: true

  # Validations
  validates :player_id, presence: true
  validates :tier, presence: true, inclusion: { in: 1..3, message: "must be 1, 2, or 3" }
  validates :day, presence: true, inclusion: { in: 1..3, message: "must be 1, 2, or 3" }
  validates :claimed_at, presence: true

  # Unique constraint validation (in addition to DB index)
  validates :tier, uniqueness: {
    scope: [:player_id, :day],
    message: "and day combination already claimed for this player"
  }

  # Callbacks
  before_validation :set_claimed_at, on: :create

  # Scopes for easy querying
  scope :for_player, ->(player_id) { where(player_id: player_id) }
  scope :for_tier, ->(tier) { where(tier: tier) }
  scope :for_day, ->(day) { where(day: day) }
  scope :for_player_and_tier, ->(player_id, tier) { where(player_id: player_id, tier: tier) }

  # Helper method to check if player has claimed specific tier and day
  def self.claimed?(player_id, tier, day)
    exists?(player_id: player_id, tier: tier, day: day)
  end

  # Helper method to get all claims for a player and tier
  def self.get_player_tier_claims(player_id, tier)
    where(player_id: player_id, tier: tier).order(:day)
  end

  private

  def set_claimed_at
    self.claimed_at ||= Time.current
  end
end
