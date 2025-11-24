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

  # Developer-only purchase action for testing IAP flow in development environment
  # SAFETY: Only works in development mode with specific developer device ID
  DEVELOPER_DEVICE_ID = "7C52EB7B-B58D-51CF-B567-7B6CD124188D".freeze

  def dev_purchase(json)
    _json = JSON.parse(json['json'])

    # SAFETY CHECK 1: Only allow in development environment
    unless Rails.env.development?
      Rails.logger.error "[DEV_PURCHASE] BLOCKED: Attempted dev_purchase in #{Rails.env} environment"
      return render_error "dev_purchase", json, "Dev purchase only allowed in development environment", 403
    end

    # SAFETY CHECK 2: Verify developer device ID
    device_id = _json['device_id']
    unless device_id == DEVELOPER_DEVICE_ID
      Rails.logger.error "[DEV_PURCHASE] BLOCKED: Invalid device ID: #{device_id}"
      return render_error "dev_purchase", json, "Invalid device ID for dev purchase", 403
    end

    product_id = _json['product_id']
    is_editor_test = _json['is_editor_test'] || false

    # Log prominently for visibility
    Rails.logger.warn "=" * 60
    Rails.logger.warn "[DEV_PURCHASE] DEVELOPER PURCHASE INITIATED"
    Rails.logger.warn "[DEV_PURCHASE] Player ID: #{params[:user_id]}"
    Rails.logger.warn "[DEV_PURCHASE] Product ID: #{product_id}"
    Rails.logger.warn "[DEV_PURCHASE] Device ID: #{device_id}"
    Rails.logger.warn "[DEV_PURCHASE] Editor Test: #{is_editor_test}"
    Rails.logger.warn "[DEV_PURCHASE] Timestamp: #{Time.current}"
    Rails.logger.warn "=" * 60

    begin
      # Step 1: Create order using existing Purchase.process
      # Build params in the same format as real payment action
      purchase_params = {
        "product_id" => product_id,
        "platform" => "unity",  # Use unity platform to skip validation in callback
        "is_sandbox" => true
      }

      order = Purchase.new(params[:user_id], purchase_params).process
      Rails.logger.warn "[DEV_PURCHASE] Order created: #{order.order_id}"

      # Step 2: Immediately process callback using existing PurchaseCallback
      # Build callback params in the same format as real callback action
      callback_params = {
        "order_id" => order.order_id,
        "platform_order_id" => "dev_purchase_#{SecureRandom.hex(8)}",
        "receipt_data" => nil  # Not needed for unity platform
      }

      reward_items = PurchaseCallback.new(params[:user_id], callback_params).callback
      Rails.logger.warn "[DEV_PURCHASE] Purchase completed successfully"
      Rails.logger.warn "[DEV_PURCHASE] Rewards: #{reward_items.inspect}"

      # Return response in same format as real callback
      render_response "dev_purchase", json, {
        order_id: order.order_id,
        rewards: reward_items,
        Player: Player.find(params[:user_id]).as_ws_json
      }

    rescue StandardError => e
      Rails.logger.error "[DEV_PURCHASE] ERROR: #{e.message}"
      Rails.logger.error "[DEV_PURCHASE] Backtrace: #{e.backtrace.first(5).join("\n")}"
      render_error "dev_purchase", json, e.message, 500
    end
  end
end
