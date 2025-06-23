# frozen_string_literal: true

class PlayerResource
  attr_accessor :diamond, :gold_coin, :items, :stamina, :exp
  def initialize(resource)
    resource.deep_symbolize_keys!
    @diamond = resource[:diamond] || 0
    @gold_coin = resource[:gold_coin] || 0
    @items = resource[:items] || {}
    @stamina = resource[:stamina] || 0
    @exp = resource[:exp] || 0
  end

  def as_ws_json(options = nil)
    {
      diamond: @diamond,
      gold_coin: @gold_coin,
      stamina: @stamina,
      exp: @exp,
      items: @items
    }
  end

  def validate_add
    raise ArgumentError "diamond cannot be negative" if @diamond < 0
    raise ArgumentError "gold_coin cannot be negative" if @gold_coin < 0
    raise ArgumentError "stamina cannot be negative" if @stamina < 0
    raise ArgumentError "exp cannot be negative" if @exp < 0

    @items.each do |item_id, count|
      base_item = BaseItem.find_by(id: item_id)
    end

  end
end
