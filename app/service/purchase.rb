# frozen_string_literal: true

class Purchase

  include Payment

  def initialize(player_id,params)
    @player_id = player_id
    @params = params
  end

  def process
    BaseValidator.new(@params).validate!
    # SignatureValidator.new(@params).validate!

    # Fetch product to get pricing information
    product = PurchaseProduct.find_by(product_id: @params["product_id"])
    raise ArgumentError, "Product not found: #{@params['product_id']}" unless product

    Order.create!(
      player_id: @player_id,
      product_id: @params["product_id"],
      platform: @params["platform"],
      is_sandbox: @params["is_sandbox"],
      money: product.money,
      currency: product.currency,
      status: 'pending'
    )
  end
end
