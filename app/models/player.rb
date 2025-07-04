class Player < ApplicationRecord
  has_one :user
  has_one :hero

  has_many :sidekicks
  has_many :equipments
  has_many :gemstones
  has_many :battle_formations

  before_create :init_by_before_create
  after_create :init_by_after_create

  include Redis::Objects

  value :weekly_periodic_rewards_received_date
  value :monthly_periodic_rewards_received_date

  def get_gemstone_entries_summary
    Gemstone.get_gemstone_entries_summary(self.equipments.map(&:gemstones).flatten)
  end

  def add_item(id_or_name, count = 1, reason = nil)
    validate_change_item_params(id_or_name, count)
    item_name = BaseItem.get_name(id_or_name)
    self.items_json ||= {}
    self.items_json[item_name] ||= 0
    self.items_json[item_name] += count
  end

  def remove_item(id_or_name, count = 1, reason = nil)
    validate_cost_item_count(id_or_name, count)
    item_name = BaseItem.get_name(id_or_name)
    self.items_json[item_name] -= count
  end

  def add_item!(id_or_name, count = 1, reason = nil)
    add_item(id_or_name, count, reason)
    save!
  end

  def remove_item!(id_or_name, count = 1, reason = nil)
    remove_item(id_or_name, count, reason)
    save!
  end


  def receive_award(reward = {})
    ApplicationRecord.transaction do
      diamond = reward["diamond"] || 0
      gold_coin = reward["gold_coin"] || 0
      items = reward["items"] || {}
      stamina = reward["stamina"] || 0
      if diamond > 0
        self.diamond ||= 0
        self.diamond += diamond
      end
      if gold_coin > 0
        self.gold_coin ||= 0
        self.gold_coin += gold_coin
      end
      if stamina > 0
        self.stamina ||= 0
        self.stamina += stamina
      end
      items.each do |item_id, count|
        self.add_item(item_id, count)
      end
      self.save!
    end
  end

  def receive_award!(reward = {})
    receive_award(reward)
    save!
  end

  def validate_change_item_params(id_or_name, count)
    raise ArgumentError, "Item cannot be blank." if id_or_name.blank?
    raise ArgumentError, "The operation quantity must be greater than 0." if count <= 0
    raise ArgumentError, "Item not found." unless BaseItem.exists?(id_or_name)
  end

  def validate_cost_item_count(id_or_name, count)
    raise ArgumentError, "Item cannot be blank." if id_or_name.blank?
    raise ArgumentError, "The operation quantity must be greater than 0." if count <= 0
    raise ArgumentError, "Item not found." unless BaseItem.exists?(id_or_name)
    item_name = BaseItem.get_name(id_or_name)
    self.items_json ||= {}
    self.items_json[item_name] ||= 0
    raise ArgumentError, "Not enough items." if self.items_json[item_name] < count
  end

  private

  def init_by_before_create
    # This method is called before the player is created.
    # You can add any initialization logic here.
    # For example, you might want to set default values for attributes.
    self.items_json = {}
    self.draw_times = {}
  end


  def init_by_after_create
    # This method is called after the player is created.
    # You can add any initialization logic here.
    # For example, you might want to create a default hero or sidekick.
    self.create_hero(name: "Default Hero")
  end
end
