# app/services/payment/order_validator.rb
module Payment
  class OrderValidator
    def initialize(player_id,params)
      @player_id = player_id
      @order_id = params["order_id"]
      @money = params["money"]
      @currency = params["currency"]
      @product_id = params["product_id"]
      @is_sandbox = params["is_sandbox"]
    end

    def validate!
      order = Order.find_by(order_id: @order_id)
      raise ArgumentError, ErrorMsg::ORDER_NOT_FOUND if order.nil?
      raise ArgumentError, ErrorMsg::PLAYER_NOT_MATCH unless order.player_id == @player_id
      raise ArgumentError, ErrorMsg::CURRENCY_NOT_MATCH unless order.currency == @currency
      raise ArgumentError, ErrorMsg::PRODUCT_NOT_MATCH unless order.product_id == @product_id

      # 如果订单是沙盒环境，检查is_sandbox字段
      if @is_sandbox && !order.is_sandbox
        raise ArgumentError, ErrorMsg::INVALID_PLATFORM % "Sandbox environment not supported for this order"
      end
      order
    end
  end
end
