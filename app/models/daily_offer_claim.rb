class DailyOfferClaim < ApplicationRecord
  belongs_to :player

  validates :product_id, :claimed_date, :claimed_at, presence: true
  validates :player_id, :product_id, :claimed_date, uniqueness: { scope: [:player_id, :product_id, :claimed_date] }

  # Check if a player has already claimed a specific daily offer today (based on player's regional time)
  def self.claimed_today?(player_id, product_id)
    today = Time.now.to_date
    exists?(player_id: player_id, product_id: product_id, claimed_date: today)
  end

  # Get all daily offers claimed by a player today (based on player's regional time)
  def self.claimed_today_by_player(player_id)
    today = Time.now.to_date
    where(player_id: player_id, claimed_date: today).pluck(:product_id)
  end

  # Create a claim record for a daily offer purchase (based on player's regional time)
  def self.record_claim(player_id, product_id)
    today = Time.now.to_date
    find_or_create_by(
      player_id: player_id,
      product_id: product_id,
      claimed_date: today
    ) do |claim|
      claim.claimed_at = Time.current
    end
  end
end
