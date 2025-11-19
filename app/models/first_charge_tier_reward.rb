class FirstChargeTierReward < ApplicationRecord
  # Associations
  has_many :first_charge_claims

  # Validations
  validates :tier, presence: true, inclusion: { in: 1..3, message: "must be 1, 2, or 3" }
  validates :day, presence: true, inclusion: { in: 1..3, message: "must be 1, 2, or 3" }
  validates :diamond, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :rarekey_count, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :epickey_count, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :skillbook_count, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :shard_count, presence: true, numericality: { greater_than_or_equal_to: 0 }

  # Unique constraint validation (in addition to DB index)
  validates :tier, uniqueness: { scope: :day, message: "and day combination already exists" }

  # Scopes for easy querying
  scope :for_tier, ->(tier) { where(tier: tier) }
  scope :for_day, ->(day) { where(day: day) }
  scope :for_tier_and_day, ->(tier, day) { where(tier: tier, day: day) }

  # Helper method to get reward for specific tier and day
  def self.get_reward(tier, day)
    find_by(tier: tier, day: day)
  end
end
