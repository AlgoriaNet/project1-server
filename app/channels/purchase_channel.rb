# frozen_string_literal: true

class PurchaseChannel < ApplicationCable::Channel
  def stream_name
    "purchase_channel_#{params[:user_id]}"
  end

  def dispatch_action(action, data)
    # Store the full message data so action methods can access unencrypted fields
    Rails.logger.info "[IAP] dispatch_action called - action: #{action}, data keys: #{data.keys.inspect}"
    @message_data = data
    super(action, data)
  end

  def payment(json)
    Rails.logger.info "[IAP] PAYMENT METHOD ENTRY - json parameter class: #{json.class}"
    _json = JSON.parse(json['json'])
    begin
      Rails.logger.info "[IAP] Payment action called for player #{params[:user_id]}, product: #{_json['product_id']}"
      order = Purchase.new(params[:user_id], _json).process
      Rails.logger.info "[IAP] Payment successful, order_id: #{order.order_id}"
      render_response "payment", json, {order_id: order.order_id}
    rescue StandardError => e
      Rails.logger.error "[IAP] Payment error: #{e.message}\n#{e.backtrace.join("\n")}"
      render_error "payment", json, e.message, 500
    end
  end

  def callback(json)
    Rails.logger.info "[IAP] CALLBACK METHOD ENTRY - json parameter class: #{json.class}"
    _json = JSON.parse(json['json'])

    # Debug: Log what we're receiving
    Rails.logger.info "[IAP] Callback received - json keys: #{json.keys.inspect}, message_data keys: #{@message_data&.keys&.inspect}"
    Rails.logger.info "[IAP] Parsed JSON content: #{_json.inspect}"
    Rails.logger.info "[IAP] platform_order_id from encrypted json: #{_json['platform_order_id'].inspect}"

    # Merge unencrypted fields from the raw message data (stored by dispatch_action)
    if @message_data.present?
      _json['receipt_data'] = @message_data['receipt_data'] if @message_data['receipt_data'].present?
      _json['money'] = @message_data['money'] if @message_data['money'].present?
      _json['currency'] = @message_data['currency'] if @message_data['currency'].present?
    end

    begin
      Rails.logger.info "[IAP] Callback action called for player #{params[:user_id]}, order_id: #{_json['order_id']}"
      reward_items = PurchaseCallback.new(params[:user_id], _json).callback
      Rails.logger.info "[IAP] Callback successful, rewards: #{reward_items.inspect}"
      render_response "callback", json, {rewards: reward_items, Player: Player.find(params[:user_id]).as_ws_json}
    rescue StandardError => e
      Rails.logger.error "[IAP] Callback error: #{e.message}\n#{e.backtrace.join("\n")}"
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
