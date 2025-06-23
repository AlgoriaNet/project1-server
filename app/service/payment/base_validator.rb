# app/services/payment/base_validator.rb
module Payment
  class BaseValidator
    REQUIRED_FIELDS = %w[product_id platform is_sandbox].freeze
    REQUIRED_CALLBACK_FIELDS = %w[order_id receipt_data
].freeze

    def initialize(params)
      @params = params
    end

    def validate!
      # 必填字段检查
      missing_fields = REQUIRED_FIELDS.reject { |f| @params.key?(f) }
      raise ArgumentError, ErrorMsg::MISSING_REQUIRED_FIELDS % missing_fields unless missing_fields.empty?

      # 产品ID有效性检查
      unless PurchaseProduct.exists?(product_id: @params['product_id'])
        raise ArgumentError, ErrorMsg::PRODUCT_NOT_FOUND % @params['product_id']
      end
    end

    def validate_callback!
      # 必填字段检查
      missing_fields = REQUIRED_CALLBACK_FIELDS.reject { |f| @params.key?(f) }
      raise ArgumentError, ErrorMsg::MISSING_REQUIRED_FIELDS % missing_fields unless missing_fields.empty?
      # 订单号有效性检查
      order = Order.find_by(order_id: @params['order_id'])
      raise ArgumentError, ErrorMsg::ORDER_NOT_FOUND unless order.present?
      raise ArgumentError, ErrorMsg::ORDER_NOT_PENDING unless order.pending?
      order
    end
  end
end
