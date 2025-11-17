# app/services/payment/order_validator.rb
module Payment
  class OrderValidator
    def initialize(player_id,params)
      @player_id = player_id
      @order_id = params["order_id"]
      # These values are fetched from the order, not from params (callback doesn't include them)
      @money = params["money"]
      @currency = params["currency"]
      @product_id = params["product_id"]
      @is_sandbox = params["is_sandbox"]
    end

    def validate!
      order = Order.find_by(order_id: @order_id)
      raise ArgumentError, ErrorMsg::ORDER_NOT_FOUND if order.nil?
      raise ArgumentError, ErrorMsg::PLAYER_NOT_MATCH unless order.player_id == @player_id

      # For callback validation, only validate if values were provided in params (they won't be for callback)
      # The order already has all the correct values from the initial purchase request
      if @currency.present?
        raise ArgumentError, ErrorMsg::CURRENCY_NOT_MATCH unless order.currency == @currency
      end

      if @product_id.present?
        raise ArgumentError, ErrorMsg::PRODUCT_NOT_MATCH unless order.product_id == @product_id
      end

      # 如果订单是沙盒环境，检查is_sandbox字段
      if @is_sandbox.present? && @is_sandbox && !order.is_sandbox
        raise ArgumentError, ErrorMsg::INVALID_PLATFORM % "Sandbox environment not supported for this order"
      end
      order
    end
  end
end
