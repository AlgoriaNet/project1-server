# frozen_string_literal: true

class PurchaseCallback
  include Payment

  def initialize(player_id,params)
    @player_id = player_id
    @params = params
  end

  def callback
    # 参数验证
    # SignatureValidator.new(@params).validate!
    # 基础参数验证
    Rails.logger.info "[IAP] PurchaseCallback.callback - @params keys: #{@params.keys.inspect}"
    Rails.logger.info "[IAP] receipt_data value: #{@params['receipt_data'].inspect[0..100]}"

    order = BaseValidator.new(@params).validate_callback!

    # 平台特定验证, Unity 不需要验证
    case order.platform.downcase
    when 'apple'
      Payment::AppleValidator.new(@params['receipt_data'], sandbox: order.is_sandbox).verify!
    when 'google', 'android'
      # Extract purchase token from receipt_data JSON
      Rails.logger.info "[IAP] Parsing receipt_data for Google Play validation"
      receipt_json = JSON.parse(@params['receipt_data'])
      Rails.logger.info "[IAP] Receipt JSON keys: #{receipt_json.keys.inspect}"

      # For Google Play receipts, the token is inside the Payload
      # Payload is a string that contains escaped JSON
      payload_str = receipt_json['Payload']
      Rails.logger.info "[IAP] Payload type: #{payload_str.class}, first 100 chars: #{payload_str.to_s[0..100]}"

      # Parse the Payload string first
      payload_json = JSON.parse(payload_str)
      Rails.logger.info "[IAP] Parsed Payload keys: #{payload_json.keys.inspect}"

      # The 'json' field contains another escaped JSON string with the actual purchase data
      json_str = payload_json['json']
      Rails.logger.info "[IAP] JSON field type: #{json_str.class}, first 100 chars: #{json_str.to_s[0..100]}"

      # Parse the inner json field
      purchase_data = JSON.parse(json_str)
      Rails.logger.info "[IAP] Parsed purchase_data keys: #{purchase_data.keys.inspect}"

      # Extract purchaseToken from the parsed purchase data
      purchase_token = purchase_data['purchaseToken']

      Rails.logger.info "[IAP] Extracted purchase_token: #{purchase_token.present? ? "#{purchase_token[0..20]}..." : "MISSING"}"

      unless purchase_token.present?
        raise ArgumentError, "Invalid receipt format: purchaseToken not found in receipt_data"
      end

      Payment::GoogleValidator.new(
        'com.algoria.hero',
        order.product_id,
        purchase_token
      ).verify!
    when 'unity'
      nil # Unity 平台不需要额外验证
    else
      raise ArgumentError, Payment::ErrorMsg::INVALID_PLATFORM % order.platform
    end

    # 订单验证
    order = OrderValidator.new(@player_id, @params).validate!

    # 执行发货
    reward_items = nil
    ActiveRecord::Base.transaction do
      reward_items = ProductDeliverer.new(order.order_id).deliver
      order.update!(status: :paid, deliver_time: Time.current)
    end

    if order.reload.product_id.start_with?("card_")
      PeriodicReward.receive_reward(@player_id)
    end

    reward_items
  end
end


