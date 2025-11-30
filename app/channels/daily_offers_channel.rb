# frozen_string_literal: true

class DailyOffersChannel < ApplicationCable::Channel
  def stream_name
    "daily_offers_channel_#{params[:user_id]}"
  end

  def get_claim_status(json)
    Rails.logger.info "[DailyOffers] get_claim_status called for player #{params[:user_id]}"

    begin
      claimed_today = DailyOfferClaim.claimed_today_by_player(params[:user_id])
      Rails.logger.info "[DailyOffers] Claimed today: #{claimed_today.inspect}"

      render_response "get_claim_status", json, {
        claimed_today: claimed_today,
        player_id: params[:user_id]
      }
    rescue StandardError => e
      Rails.logger.error "[DailyOffers] Error getting claim status: #{e.message}"
      render_error "get_claim_status", json, e.message, 500
    end
  end
end
