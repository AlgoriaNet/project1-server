# frozen_string_literal: true

require 'test_helper' # 必须确保加载test_helper
require 'digest'

class PaymentTest < ActiveSupport::TestCase

  # test "create order" do
  #   player_id = 1
  #
  #   product = PurchaseProduct.first
  #   params = {
  #     product_id: product.product_id,
  #     money: product.money,
  #     currency: product.currency,
  #     platform: "unity",
  #     is_sandbox: true,
  #   }
  #
  #   sign_str = params.sort.map { |k, v| "#{k}=#{v}" }.join('&') + Rails.application.credentials[:secret_key_base]
  #   params[:sign] = Digest::MD5.hexdigest(sign_str)
  #
  #   order = Purchase.new(player_id, params.stringify_keys).process
  #   puts "Order created: #{order.inspect}"
  #   assert order.persisted?, "Order should be persisted"
  # end
  #
  # test "callback test" do
  #   player_id = 1
  #   product = PurchaseProduct.find_by(product_id: 'card_999')
  #   params = {
  #     product_id: product.product_id,
  #     money: product.money,
  #     currency: product.currency,
  #     platform: "unity",
  #     is_sandbox: true,
  #   }
  #
  #   sign_str = params.sort.map { |k, v| "#{k}=#{v}" }.join('&') + Rails.application.credentials[:secret_key_base]
  #   params[:sign] = Digest::MD5.hexdigest(sign_str)
  #
  #   order = Purchase.new(player_id, params.stringify_keys).process
  #
  #   params.delete(:sign)
  #   params.merge!({ order_id: order.order_id, receipt_data: "example_receipt_data" })
  #   sign_str = params.sort.map { |k, v| "#{k}=#{v}" }.join('&') + Rails.application.credentials[:secret_key_base]
  #   params[:sign] = Digest::MD5.hexdigest(sign_str)
  #
  #   order = PurchaseCallback.new(player_id, params.stringify_keys).callback
  #
  #   assert order.paid?, "Order should be marked as paid"
  # end
end
