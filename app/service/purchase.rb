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

    Order.create!(
      player_id: @player_id,
      product_id: @params["product_id"],
      platform: @params["platform"],
      is_sandbox: @params["is_sandbox"],
      status: 'pending'
    )
  end
end
