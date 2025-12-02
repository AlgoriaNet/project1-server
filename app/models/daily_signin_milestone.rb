class DailySigninMilestone < ApplicationRecord
  # Associations
  belongs_to :player

  # Validations
  validates :player_id, presence: true
  validates :cycle_number, presence: true, numericality: { greater_than: 0 }
  validates :milestone_day, presence: true,
            inclusion: { in: [7, 14, 21, 30], message: "must be 7, 14, 21, or 30" }
  validates :claimed_at, presence: true

  # Unique constraint validation
  validates :milestone_day, uniqueness: {
    scope: [:player_id, :cycle_number],
    message: "milestone already claimed for this player and cycle"
  }

  # Callbacks
  before_validation :set_claimed_at, on: :create

  # Scopes
  scope :for_player, ->(player_id) { where(player_id: player_id) }
  scope :for_cycle, ->(cycle_number) { where(cycle_number: cycle_number) }
  scope :for_player_and_cycle, ->(player_id, cycle_number) {
    where(player_id: player_id, cycle_number: cycle_number)
  }

  # Helper method to check if player has claimed specific milestone in cycle
  def self.claimed?(player_id, cycle_number, milestone_day)
    exists?(player_id: player_id, cycle_number: cycle_number, milestone_day: milestone_day)
  end

  # Get all milestones for a player in current cycle
  def self.get_player_cycle_milestones(player_id, cycle_number)
    where(player_id: player_id, cycle_number: cycle_number).order(:milestone_day)
  end

  # Get claimed milestone days for a player in a cycle
  def self.claimed_milestones(player_id, cycle_number)
    where(player_id: player_id, cycle_number: cycle_number).pluck(:milestone_day)
  end

  # Check which milestones are available but not yet claimed
  def self.available_unclaimed_milestones(player_id, cycle_number, claimed_day_count)
    claimed = claimed_milestones(player_id, cycle_number)
    [7, 14, 21, 30].select { |m| m <= claimed_day_count && !claimed.include?(m) }
  end

  private

  def set_claimed_at
    self.claimed_at ||= Time.current
  end
end
