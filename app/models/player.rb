class Player < ApplicationRecord
  has_one :user
  has_one :hero

  has_many :sidekicks
  has_many :equipments
  has_many :gemstones
  has_many :battle_formations
  has_many :first_charge_claims
  has_many :daily_offer_claims
  has_many :daily_signin_claims
  has_many :daily_signin_milestones


  before_create :init_by_before_create
  after_create :init_by_after_create

  include Redis::Objects

  value :weekly_periodic_rewards_received_date
  value :monthly_periodic_rewards_received_date

  def get_gemstone_entries_summary
    Gemstone.get_gemstone_entries_summary(self.equipments.map(&:gemstones).flatten)
  end

  # Add stamina to player
  def add_stamina!(amount)
    ApplicationRecord.transaction do
      self.stamina ||= 0
      self.stamina += amount
      save!
    end
    self
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

  # ============================================================================
  # DAILY SIGN-IN SYSTEM
  # ============================================================================

  # Generate random skillbook distribution for even days
  # Returns hash like: { "Skb_02" => 5, "Skb_07" => 8, ... } totaling 50
  def self.generate_random_skillbooks
    # Pick 10 different skillbook IDs from 01-20
    skillbook_ids = (1..20).to_a.sample(10).map { |n| "Skb_#{n.to_s.rjust(2, '0')}" }

    # Distribute 50 quantity randomly among them
    # Start with 1 for each (minimum), then distribute remaining 40 randomly
    distribution = {}
    skillbook_ids.each { |id| distribution[id] = 1 }

    remaining = 40
    while remaining > 0
      # Pick a random skillbook and add 1 to it
      lucky_id = skillbook_ids.sample
      distribution[lucky_id] += 1
      remaining -= 1
    end

    distribution
  end

  # Initialize sign-in system on first access
  def initialize_signin_if_needed
    if signin_first_date.nil?
      self.signin_first_date = Date.current
      self.signin_cycle_number = 1
      self.signin_consecutive_days = 0
      save!
    end
  end

  # Check if player has already claimed today
  def claimed_signin_today?
    signin_last_claim_date == Date.current
  end

  # Get next claimable day in current cycle
  def next_signin_day
    initialize_signin_if_needed
    claimed_days = DailySigninClaim.claimed_days(id, signin_cycle_number)
    return 1 if claimed_days.empty?

    # Find first unclaimed day
    (1..30).each do |day|
      return day unless claimed_days.include?(day)
    end

    # All 30 days claimed, advance to next cycle
    nil
  end

  # Claim daily sign-in for today
  def claim_daily_signin!
    initialize_signin_if_needed

    # Check if already claimed today
    raise ArgumentError, "Already claimed sign-in today" if claimed_signin_today?

    # Get next available day
    day_to_claim = next_signin_day

    # If nil, player completed cycle, advance to next cycle
    if day_to_claim.nil?
      self.signin_cycle_number += 1
      day_to_claim = 1
      Rails.logger.info "[DailySignin] Player #{id} completed cycle, advancing to cycle #{signin_cycle_number}"
    end

    # Get reward configuration
    reward_config = DailySigninReward.get_reward(day_to_claim)
    raise ArgumentError, "No reward configured for day #{day_to_claim}" unless reward_config

    rewards_given = {}

    ApplicationRecord.transaction do
      # Award rewards based on day type
      case reward_config.reward_type
      when "gold_coin"
        self.gold_coin ||= 0
        self.gold_coin += reward_config.gold_coin
        rewards_given["gold_coin"] = reward_config.gold_coin
        Rails.logger.debug "[DailySignin] Player #{id} claimed day #{day_to_claim}: #{reward_config.gold_coin} gold coin"

      when "skillbooks"
        # Generate random skillbook distribution
        skillbook_distribution = Player.generate_random_skillbooks
        skillbook_distribution.each do |skillbook_id, count|
          add_item(skillbook_id, count)
        end
        rewards_given["skillbooks"] = skillbook_distribution

        # Log detailed skillbook distribution
        skillbook_summary = skillbook_distribution.map { |k, v| "#{k}=#{v}" }.join(", ")
        total_count = skillbook_distribution.values.sum
        Rails.logger.debug "[DailySignin] Player #{id} claimed day #{day_to_claim}: Skillbooks awarded: #{skillbook_summary} (total #{total_count})"
      end

      # Record the claim
      DailySigninClaim.create!(
        player_id: id,
        cycle_number: signin_cycle_number,
        day_number: day_to_claim,
        reclaimed: false,
        rewards_json: rewards_given.to_json
      )

      # Update consecutive days and last claim date
      self.signin_consecutive_days += 1
      self.signin_last_claim_date = Date.current

      save!
    end

    { day_claimed: day_to_claim, rewards: rewards_given }
  end

  # Reclaim a missed day by paying 20 diamonds
  def reclaim_daily_signin!(day_number)
    initialize_signin_if_needed

    # Validate day_number
    raise ArgumentError, "Day number must be between 1 and 30" unless (1..30).include?(day_number)

    # Check if day already claimed
    if DailySigninClaim.claimed?(id, signin_cycle_number, day_number)
      raise ArgumentError, "Day #{day_number} already claimed"
    end

    # Check player has enough diamonds
    self.diamond ||= 0
    raise ArgumentError, "Not enough diamonds (need 20)" if diamond < 20

    # Get reward configuration
    reward_config = DailySigninReward.get_reward(day_number)
    raise ArgumentError, "No reward configured for day #{day_number}" unless reward_config

    rewards_given = {}

    ApplicationRecord.transaction do
      # Deduct 20 diamonds
      self.diamond -= 20

      # Award rewards based on day type
      case reward_config.reward_type
      when "gold_coin"
        self.gold_coin ||= 0
        self.gold_coin += reward_config.gold_coin
        rewards_given["gold_coin"] = reward_config.gold_coin
        Rails.logger.debug "[DailySignin] Player #{id} reclaimed day #{day_number} for 20 diamonds: #{reward_config.gold_coin} gold coin"

      when "skillbooks"
        # Generate random skillbook distribution
        skillbook_distribution = Player.generate_random_skillbooks
        skillbook_distribution.each do |skillbook_id, count|
          add_item(skillbook_id, count)
        end
        rewards_given["skillbooks"] = skillbook_distribution

        skillbook_summary = skillbook_distribution.map { |k, v| "#{k}=#{v}" }.join(", ")
        total_count = skillbook_distribution.values.sum
        Rails.logger.debug "[DailySignin] Player #{id} reclaimed day #{day_number} for 20 diamonds: Skillbooks awarded: #{skillbook_summary} (total #{total_count})"
      end

      # Record the reclaim
      DailySigninClaim.create!(
        player_id: id,
        cycle_number: signin_cycle_number,
        day_number: day_number,
        reclaimed: true,
        rewards_json: rewards_given.to_json
      )

      save!
    end

    { day_reclaimed: day_number, rewards: rewards_given, diamonds_spent: 20 }
  end

  # Claim a milestone reward
  def claim_milestone!(milestone_day)
    initialize_signin_if_needed

    # Validate milestone_day
    unless [7, 14, 21, 30].include?(milestone_day)
      raise ArgumentError, "Milestone day must be 7, 14, 21, or 30"
    end

    # Check if milestone already claimed
    if DailySigninMilestone.claimed?(id, signin_cycle_number, milestone_day)
      raise ArgumentError, "Milestone day #{milestone_day} already claimed"
    end

    # Check if player has claimed enough days
    claimed_count = DailySigninClaim.days_claimed_in_cycle(id, signin_cycle_number)
    if claimed_count < milestone_day
      raise ArgumentError, "Must claim at least #{milestone_day} days before claiming this milestone (currently #{claimed_count})"
    end

    # Get reward configuration
    reward_config = DailySigninReward.get_reward(milestone_day)
    raise ArgumentError, "No reward configured for milestone day #{milestone_day}" unless reward_config

    rewards_given = {}

    ApplicationRecord.transaction do
      # Award milestone rewards
      if reward_config.diamond > 0
        self.diamond ||= 0
        self.diamond += reward_config.diamond
        rewards_given["diamond"] = reward_config.diamond
      end

      if reward_config.epic_key > 0
        add_item("EpicKey", reward_config.epic_key)
        rewards_given["epic_key"] = reward_config.epic_key
      end

      if reward_config.hero_key > 0
        add_item("HeroKey", reward_config.hero_key)
        rewards_given["hero_key"] = reward_config.hero_key
      end

      if reward_config.rare_key > 0
        add_item("RareKey", reward_config.rare_key)
        rewards_given["rare_key"] = reward_config.rare_key
      end

      # Record the milestone claim
      DailySigninMilestone.create!(
        player_id: id,
        cycle_number: signin_cycle_number,
        milestone_day: milestone_day
      )

      save!

      Rails.logger.debug "[DailySignin] Player #{id} claimed milestone day #{milestone_day}: #{rewards_given.inspect}"
    end

    { milestone_claimed: milestone_day, rewards: rewards_given }
  end

  # Get current sign-in status for player
  def signin_status
    initialize_signin_if_needed

    claimed_days = DailySigninClaim.claimed_days(id, signin_cycle_number)
    claimed_milestones = DailySigninMilestone.claimed_milestones(id, signin_cycle_number)
    next_day = next_signin_day

    {
      cycle_number: signin_cycle_number,
      first_date: signin_first_date,
      last_claim_date: signin_last_claim_date,
      consecutive_days: signin_consecutive_days,
      claimed_days: claimed_days,
      claimed_milestones: claimed_milestones,
      next_claimable_day: next_day,
      claimed_today: claimed_signin_today?,
      days_claimed_count: claimed_days.count,
      available_unclaimed_milestones: DailySigninMilestone.available_unclaimed_milestones(
        id, signin_cycle_number, claimed_days.count
      )
    }
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

  # Override as_ws_json to ensure summoned_allies is always included
  def as_ws_json(options = nil)
    Rails.logger.info "[Perf] Player#as_ws_json START at #{Time.now.to_f}"
    # Ensure summoned_allies is always an array, never nil
    attrs = super(options)
    attrs['summoned_allies'] = summoned_allies || []
    Rails.logger.info "[Perf] Player#as_ws_json END at #{Time.now.to_f}"
    attrs
  end

  private

  def init_by_before_create
    # This method is called before the player is created.
    # You can add any initialization logic here.
    # For example, you might want to set default values for attributes.
    self.items_json = {}
    self.draw_times = {}
    self.summoned_allies = []
  end


  def init_by_after_create
    # This method is called after the player is created.
    # You can add any initialization logic here.
    # For example, you might want to create a default hero or sidekick.
    self.create_hero(name: "Default Hero")
  end
end
