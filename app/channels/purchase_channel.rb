# frozen_string_literal: true

class PurchaseChannel < ApplicationCable::Channel
  def stream_name
    "purchase_channel_#{params[:user_id]}"
  end

  def payment(json)
    _json = JSON.parse(json['json'])
    begin
      order =Purchase.new(params[:user_id], _json).process
      render_response "payment", json, order
    rescue StandardError => e
      Rails.logger.error "Purchase error: #{e.message}"
      render_error "payment", json, e.message, 500
    end
  end

  def callback(json)
    _json = JSON.parse(json['json'])
    begin
      reward_items = PurchaseCallback.new(params[:user_id], _json).callback
      render_response "callback", json, {rewards: reward_items, Player: Player.find(params[:user_id]).as_ws_json}
    rescue StandardError => e
      Rails.logger.error "Callback error: #{e.message}"
      render_error "callback", json, e.message, 500
    end
  end

  def add_gold(json)
    type = JSON.parse(json['json'])['type']
    Rails.logger.info "add_gold_type: #{type}"
    Rails.logger.info "player id: #{params[:user_id]}"
    if type == '300'
      cost_diamond = 10
      add_gold = 300
    elsif type == '1200'
      cost_diamond = 90
      add_gold = 1200
    elsif type == '4000'
      cost_diamond = 200
      add_gold = 4000
    else
      return render_error "add_gold", json, "Invalid gold type", 400
    end

    player = Player.find(params[:user_id])
    if player.diamond >= cost_diamond
      player.diamond -= cost_diamond
      player.gold_coin += add_gold
      player.save!
      render_response "add_gold", json, {gold: player.gold_coin, diamond: player.diamond}
    else
      render_error "add_gold", json, "Not enough diamonds", 400
    end
  end

  def add_ad_gold(json)
    _json = JSON.parse(json['json'])
    begin
      gold_coin = _json['type']
      unless %w[100 200 300 400 500].include?(gold_coin)
        return render_error "ad_draw_coin", json, "Invalid gold type", 400
      end
      player = Player.find(params[:user_id])
      player.gold_coin += gold_coin.to_i
      player.save!
      render_response "ad_draw_coin", json, {gold: player.gold_coin}
    rescue StandardError => e
      Rails.logger.error "Ad draw coin error: #{e.message}"
      render_error "ad_draw_coin", json, e.message, 500
    end
  end
end
