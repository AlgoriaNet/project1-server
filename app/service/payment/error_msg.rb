# frozen_string_literal: true

module Payment
  class ErrorMsg

    # Error messages for payment processing
    TIMESTAMP_TOO_OLD = "timestamp is too old or too new"
    INVALID_MONEY = "money is invalid"
    MISSING_REQUIRED_FIELDS = 'deficiency of required fields: %s'
    ORDER_NOT_FOUND = 'Order not found'
    ORDER_NOT_PENDING = 'Order is not pending'
    ORDER_ALREADY_PAID = 'Order is already paid'
    MONEY_NOT_MATCH = 'Amount does not match'
    PRODUCT_NOT_MATCH = 'Product ID does not match'
    PLAYER_NOT_MATCH = 'Player ID does not match'
    SIGNATURE_NOT_MATCH = 'Signature does not match'
    SIGNATURE_REQUIRED = 'Signature required'
    INVALID_PLATFORM = 'Platform not supported: %s'
    CURRENCY_NOT_MATCH = 'Currency does not match'
    PRODUCT_NOT_FOUND = 'Product not found: %s'
  end
end
