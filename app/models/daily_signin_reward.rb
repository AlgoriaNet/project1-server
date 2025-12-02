class DailySigninReward < ApplicationRecord
  # Validations
  validates :day_number, presence: true,
            inclusion: { in: 1..30, message: "must be between 1 and 30" },
            uniqueness: true
  validates :reward_type, presence: true,
            inclusion: { in: %w[gold_coin skillbooks milestone], message: "must be gold_coin, skillbooks, or milestone" }
  validates :gold_coin, numericality: { greater_than_or_equal_to: 0 }
  validates :skillbook_count, numericality: { greater_than_or_equal_to: 0 }
  validates :diamond, numericality: { greater_than_or_equal_to: 0 }
  validates :epic_key, numericality: { greater_than_or_equal_to: 0 }
  validates :hero_key, numericality: { greater_than_or_equal_to: 0 }
  validates :rare_key, numericality: { greater_than_or_equal_to: 0 }

  # Scopes
  scope :for_day, ->(day) { where(day_number: day) }
  scope :milestones, -> { where(day_number: [7, 14, 21, 30]) }
  scope :regular_days, -> { where.not(day_number: [7, 14, 21, 30]) }

  # Helper method to get reward for specific day
  def self.get_reward(day_number)
    find_by(day_number: day_number)
  end

  # Helper to check if a day is a milestone
  def self.milestone_day?(day_number)
    [7, 14, 21, 30].include?(day_number)
  end

  # Get milestone days that have been reached based on claimed days
  def self.available_milestones(claimed_day_numbers)
    max_day = claimed_day_numbers.max || 0
    [7, 14, 21, 30].select { |m| m <= max_day }
  end
end
