# app/services/payment/product_deliverer.rb module Payment
module Payment
  class ProductDeliverer
    def initialize(order_id)
      @order_id = order_id
      @order = Order.find_by(order_id: order_id)
      @player_id = @order.player_id
      @player = Player.find(@player_id)
      @product = PurchaseProduct.find_by(product_id: @order.product_id)
    end

    def deliver
      ActiveRecord::Base.transaction do
        reward = @product.reward_items
        # 发放货币
        @player.diamond += reward["diamond"] if reward["diamond"].present?
        # 发放物品
        items = reward["items"] || {}
        items.each do |item_id, count|
          @player.add_item!(item_id, count)
        end
        # 记录日志
        if @product.product_id.start_with?("card_")
          card_purchased
        end
        @player.save!
        @product.reward_items
      end
    end

    def card_purchased
      res = {
        purchased_type: "new",
        card_type: nil,
        weekly_card_expiry: @player.weekly_card_expiry,
        monthly_card_expiry: @player.monthly_card_expiry,
      }

      case @product.product_id
      when "card_999"
        res[:card_type] = "weekly"
        expiry =  @player.weekly_card_expiry
        if expiry.nil? || expiry.to_date < Time.current.to_date
          res[:purchased_type] = "new"
          res[:weekly_card_expiry] = (Time.current + 7.days).to_date.to_s
          @player.weekly_card_expiry = res[:weekly_card_expiry]
        else
          res[:purchased_type] = "renew"
          res[:weekly_card_expiry] = (expiry.to_date + 8.days).to_s
          @player.weekly_card_expiry = res[:weekly_card_expiry]
        end
      when "card_2999"
        res[:card_type] = "monthly"
        expiry = @player.monthly_card_expiry
        if expiry.nil? || expiry.to_date < Time.current.to_date
          res[:purchased_type] = "new"
          res[:monthly_card_expiry] = (Time.current + 30.days).to_date.to_s
          @player.monthly_card_expiry = res[:monthly_card_expiry]
        else
          res[:purchased_type] = "renew"
          res[:monthly_card_expiry] = (expiry.to_date + 30.days).to_s
          @player.monthly_card_expiry = res[:monthly_card_expiry]
          @player.save!
        end
      end
      res
    end
  end
end



