# frozen_string_literal: true

class ResourceService
  attr_reader :player_id, :resource
  def initialize(player_id, resource_params = {})
    @player_id = player_id
    @player = Player.find(player_id)
    @resource = PlayerResource.new(resource_params)
  end

  def add_resource!
    add_resource
    @player.save!
  end

  def cost_resource!
    cost_resource
    @player.save!
  end

  def add_resource
    validate_add!
    @player.diamond ||= 0
    @player.diamond += diamond
    @player.gold_coin ||= 0
    @player.gold_coin += gold_coin
    @player.stamina ||= 0
    @player.stamina += stamina
    @player.exp ||= 0
    @player.exp += exp
    @resource.items.each do |item_id, count|
      @player.add_item(item_id, count)
    end
    @resource
  end

  def cost_resource
    validate_cost!
    @player.diamond ||= 0
    @player.diamond -= @resource.diamond
    @player.gold_coin ||= 0
    @player.gold_coin -= @resource.gold_coin
    @player.stamina ||= 0
    @player.stamina -= @resource.stamina
    @player.exp ||= 0
    @player.exp -= @resource.exp
    @resource.items.each do |item_id, count|
      @player.remove_item(item_id, count)
    end
    @resource
  end

  private

  def validate_add!
    raise ArgumentError "add diamond cannot be negative" if @resource.diamond < 0
    raise ArgumentError "add gold_coin cannot be negative" if @resource.gold_coin < 0
    raise ArgumentError "add stamina cannot be negative" if @resource.stamina < 0
    raise ArgumentError "add exp cannot be negative" if @resource.exp < 0

    @resource.items.each do |item_id, count|
      @player.validate_change_item_params(item_id, count)
    end
  end

  def validate_cost!
    raise ArgumentError "cost diamond cannot be negative" if @resource.diamond < 0
    raise ArgumentError "cost gold_coin cannot be negative" if @resource.gold_coin < 0
    raise ArgumentError "cost stamina cannot be negative" if @resource.stamina < 0
    raise ArgumentError "cost exp cannot be negative" if @resource.exp < 0

    @resource.items.each do |item_id, count|
      @player.validate_cost_item_count(item_id, count)
    end
  end
end
