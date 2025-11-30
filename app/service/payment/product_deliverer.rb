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
      reward_result = nil
      ActiveRecord::Base.transaction do
        # Handle FirstCharge products separately - rewards are delivered via claim_reward endpoint
        if first_charge_tier = get_first_charge_tier(@product.product_id)
          Rails.logger.info "[ProductDeliverer] Creating FirstCharge purchase marker for player #{@player_id}, tier #{first_charge_tier}, product #{@product.product_id}"
          # For FirstCharge, just create the purchase marker (day 0 claim)
          # Actual rewards are claimed individually via claim_reward endpoint
          FirstChargeClaim.find_or_create_by(
            player_id: @player_id,
            tier: first_charge_tier,
            day: 0
          ) do |claim|
            claim.claimed_at = Time.current
          end
          Rails.logger.info "[ProductDeliverer] FirstCharge purchase marker created successfully for tier #{first_charge_tier}"
          reward_result = { message: "FirstCharge purchase registered" }
        elsif is_daily_offer?(@product.product_id)
          # Handle daily offers - deliver rewards immediately and record the claim
          Rails.logger.info "[ProductDeliverer] Processing daily offer for player #{@player_id}, product #{@product.product_id}"
          handler = DailyOfferHandler.new(@player_id, @product.product_id)

          # Check if already claimed today
          if handler.already_claimed_today?
            Rails.logger.warn "[ProductDeliverer] Player #{@player_id} already claimed #{@product.product_id} today"
            reward_result = { message: "Daily offer already claimed today", error: true }
          else
            reward_result = handler.deliver_rewards
          end
        else
          # Handle regular purchases (diamonds, cards, etc.)
          reward = @product.reward_items
          if reward.present?
            # 发放货币
            @player.diamond += reward["diamond"] if reward["diamond"].present?
            # 发放物品
            items = reward["items"] || {}
            items.each do |item_id, count|
              @player.add_item!(item_id, count)
            end
          end

          # Handle subscription card logic
          if @product.product_id.start_with?("card_")
            reward_result = card_purchased
          else
            reward_result = @product.reward_items
          end
        end

        @player.save!
      end
      reward_result
    end

    private

    def get_first_charge_tier(product_id)
      case product_id
      when "first_1499"
        1
      when "first_499"
        2
      when "first_99"
        3
      else
        nil
      end
    end

    def is_daily_offer?(product_id)
      product_id.start_with?("daily_")
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
        end
      end
      res
    end
  end
end



