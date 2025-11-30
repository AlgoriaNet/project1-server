# frozen_string_literal: true

class DailyOfferHandler
  include Payment

  DAILY_OFFER_PRODUCTS = {
    'daily_99' => {
      diamond: 60,
      gold_coin: 500,
      rarekey: 10
    },
    'daily_199' => {
      diamond: 120,
      gold_coin: 500,
      rarekey: 5,
      epickey: 5
    },
    'daily_499' => {
      diamond: 330,
      gold_coin: 500,
      rarekey: 2,
      epickey: 3,
      herokey: 5
    }
  }.freeze

  def initialize(player_id, product_id)
    @player_id = player_id
    @product_id = product_id
    @player = Player.find(player_id)
  end

  # Check if player has already claimed this daily offer today
  def already_claimed_today?
    DailyOfferClaim.claimed_today?(@player_id, @product_id)
  end

  # Get the rewards for this daily offer product
  def get_rewards
    DAILY_OFFER_PRODUCTS[@product_id] || {}
  end

  # Apply rewards to player and record the claim
  def deliver_rewards
    rewards = get_rewards
    return {} if rewards.empty?

    ActiveRecord::Base.transaction do
      # Apply each reward type
      @player.diamond += rewards[:diamond] if rewards[:diamond]
      @player.gold_coin += rewards[:gold_coin] if rewards[:gold_coin]

      # Add items (keys, etc.)
      @player.add_item('rarekey', rewards[:rarekey]) if rewards[:rarekey]
      @player.add_item('epickey', rewards[:epickey]) if rewards[:epickey]
      @player.add_item('herokey', rewards[:herokey]) if rewards[:herokey]

      @player.save!

      # Record the claim for daily reset tracking
      DailyOfferClaim.record_claim(@player_id, @product_id)

      Rails.logger.info "[DailyOffer] Delivered rewards for #{@product_id} to player #{@player_id}: #{rewards.inspect}"

      # Return the rewards for display
      rewards
    end
  end

  # Get status of all daily offers for the player (which ones are claimed today)
  def self.get_player_daily_offers_status(player_id)
    claimed_today = DailyOfferClaim.claimed_today_by_player(player_id)
    {
      daily_99: claimed_today.include?('daily_99'),
      daily_199: claimed_today.include?('daily_199'),
      daily_499: claimed_today.include?('daily_499')
    }
  end
end
