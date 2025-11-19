# frozen_string_literal: true

class MembershipCardClaim < ApplicationRecord
  belongs_to :player

  # Validations
  validates :player_id, presence: true
  validates :card_type, presence: true, inclusion: { in: %w(weekly monthly) }
  validates :day_number, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :claimed_at, presence: true

  # Set claimed_at timestamp automatically on creation
  before_create :set_claimed_at

  # Scopes
  scope :for_player, ->(player_id) { where(player_id: player_id) }
  scope :for_card_type, ->(card_type) { where(card_type: card_type) }

  class << self
    # Check if a specific reward has already been claimed
    def claimed?(player_id, card_type, day_number)
      exists?(player_id: player_id, card_type: card_type, day_number: day_number)
    end

    # Get all claimed days for a player and card type
    def claimed_days(player_id, card_type)
      for_player(player_id).for_card_type(card_type).pluck(:day_number).sort
    end
  end

  private

  def set_claimed_at
    self.claimed_at = Time.current if claimed_at.blank?
  end
end
