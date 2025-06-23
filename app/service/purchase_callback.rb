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
    order = BaseValidator.new(@params).validate_callback!

    # 平台特定验证, Unity 不需要验证
    case order.platform
    when 'apple'
      Payment::AppleValidator.new(params[:receipt_data], sandbox: order.sandbox?).verify!
    when 'google'
      Payment::GoogleValidator.new(
        'com.yourgame.package', # 替换为你的包名
        order.product_id,
        params[:receipt_data]
      ).verify!
    when 'unity'
      nil # Unity 平台不需要额外验证
    else
      raise ArgumentError, ErrorMsg.INVALID_PLATFORM % order.platform
    end

    # 订单验证
    order = OrderValidator.new(@player_id, @params).validate!

    # 执行发货
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


