class DailySigninClaim < ApplicationRecord
  # Associations
  belongs_to :player

  # Validations
  validates :player_id, presence: true
  validates :cycle_number, presence: true, numericality: { greater_than: 0 }
  validates :day_number, presence: true,
            inclusion: { in: 1..30, message: "must be between 1 and 30" }
  validates :claimed_at, presence: true

  # Unique constraint validation
  validates :day_number, uniqueness: {
    scope: [:player_id, :cycle_number],
    message: "already claimed for this player and cycle"
  }

  # Callbacks
  before_validation :set_claimed_at, on: :create

  # Scopes
  scope :for_player, ->(player_id) { where(player_id: player_id) }
  scope :for_cycle, ->(cycle_number) { where(cycle_number: cycle_number) }
  scope :for_player_and_cycle, ->(player_id, cycle_number) {
    where(player_id: player_id, cycle_number: cycle_number)
  }
  scope :reclaimed_only, -> { where(reclaimed: true) }
  scope :regular_claims, -> { where(reclaimed: false) }

  # Serialize rewards_json as JSON
  serialize :rewards_json, coder: JSON

  # Helper method to check if player has claimed specific day in cycle
  def self.claimed?(player_id, cycle_number, day_number)
    exists?(player_id: player_id, cycle_number: cycle_number, day_number: day_number)
  end

  # Get all claims for a player in current cycle
  def self.get_player_cycle_claims(player_id, cycle_number)
    where(player_id: player_id, cycle_number: cycle_number).order(:day_number)
  end

  # Get claimed day numbers for a player in a cycle
  def self.claimed_days(player_id, cycle_number)
    where(player_id: player_id, cycle_number: cycle_number).pluck(:day_number)
  end

  # Get next available day for player in cycle
  def self.next_claimable_day(player_id, cycle_number)
    claimed = claimed_days(player_id, cycle_number)
    return 1 if claimed.empty?

    # Find the first unclaimed day from 1-30
    (1..30).each do |day|
      return day unless claimed.include?(day)
    end

    # All days claimed
    nil
  end

  # Count how many days claimed in current cycle
  def self.days_claimed_in_cycle(player_id, cycle_number)
    where(player_id: player_id, cycle_number: cycle_number).count
  end

  private

  def set_claimed_at
    self.claimed_at ||= Time.current
  end
end
