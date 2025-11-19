# frozen_string_literal: true

class MembershipCardReward < ApplicationRecord
  # Validations
  validates :card_type, presence: true, inclusion: { in: %w(weekly monthly) }
  validates :diamond_one_time, :gold_per_day, :diamond_per_day, :rarekey_per_day,
            :epickey_per_day, :stamina_per_day, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  # Scopes
  scope :weekly, -> { where(card_type: 'weekly') }
  scope :monthly, -> { where(card_type: 'monthly') }

  class << self
    # Find reward config for a specific card type
    def for_card_type(card_type)
      where(card_type: card_type).first
    end

    # Get all rewards in a format suitable for frontend
    # Returns hash with 'weekly' and 'monthly' keys
    def all_for_frontend
      {
        weekly: format_for_frontend(weekly.first),
        monthly: format_for_frontend(monthly.first)
      }
    end

    private

    def format_for_frontend(reward)
      return {} unless reward.present?

      {
        diamond_one_time: reward.diamond_one_time,
        diamond_per_day: reward.diamond_per_day,
        gold_per_day: reward.gold_per_day,
        rarekey_per_day: reward.rarekey_per_day,
        epickey_per_day: reward.epickey_per_day,
        stamina_per_day: reward.stamina_per_day
      }
    end
  end
end
