# frozen_string_literal: true

class DrawService
  # 配置常量
  GEM_CONFIG = {
    'rare gem' => {
      guarantee_gem_level: 3,
      guarantee_gem_count: 10,
      guarantee_gem_field: 'guarantee_rare_gem',
      probability: CsvConfig.load_rare_gem
    },
    'epic gem' => {
      guarantee_gem_level: 4,
      guarantee_gem_count: 10,
      guarantee_gem_field: 'guarantee_epic_gem',
      probability: CsvConfig.load_epic_gem
    },
    'hero' => {
      probability: CsvConfig.load_probability_hero
    }
  }.freeze

  # Free claim limits per card pool type
  FREE_CLAIM_LIMITS = {
    'hero' => 1,
    'rare' => 3,
    'epic' => 3
  }.freeze

  attr_reader :player, :card_pool_type, :consume_item, :count

  ##
  # 初始化抽卡服务
  # @param player_id [Integer] 玩家ID
  # @param params [Hash] 抽卡参数
  #   - card_pool_type [String] 卡池类型 ('rare_gem', 'epic_gem', 'hero')
  #   - consume_item [String] 消耗物品 ('gold', 'diamond', 'ad')
  #   - count [Integer] 抽卡次数 (1 或 10)
  # @raise [ArgumentError] 如果参数无效
  def initialize(player_id, params)
    @player = Player.find(player_id)
    @card_pool_type = params['card_pool_type'].downcase
    @consume_item = params['consume_item'].downcase
    @count = calculate_count(params)
    @cost_configs = CsvConfig.load_draw_cost

    validate_parameters!
  end

  ##
  # 执行抽卡操作
  # @return [Array<Gemstone>|Gemstone] 抽卡结果
  def draw
    ApplicationRecord.transaction do
      cost_resource!
      track_free_claim! if @consume_item == 'ad'
      draw_items
    end
  end

  private

  def calculate_count(params)
    @consume_item == 'ad' ? 1 : params['count'].to_i
  end

  def validate_parameters!
    raise ArgumentError, 'draw count must be 1 or 10' unless [1, 10].include?(@count)
    raise ArgumentError, 'draw card pool type must be "rare gem", "epic gem" or "hero"' unless valid_card_pool_type?
    raise ArgumentError, 'consume item must be "key", "diamond" or "ad"' if %w[key diamond ad].exclude?(@consume_item)
    raise ArgumentError, 'cost config not found' if cost_config.blank?

    # Validate free claims if consuming via ad
    if @consume_item == 'ad'
      validate_free_claim!
    end

    # 检查玩家资源是否足够
    unless ResourceService.new(@player.id, cost_resource).validate_cost!
      raise ArgumentError, 'player resource not enough'
    end
  end

  def valid_card_pool_type?
    GEM_CONFIG.key?(@card_pool_type) || @card_pool_type == 'hero'
  end

  def cost_config
    @cost_config ||= @cost_configs.find do |c|
      c[:card_pool_type] == @card_pool_type &&
        c[:consume_item] == @consume_item &&
        c[:count] == @count
    end
  end

  def cost_resource
    cost_config[:cost]
  end

  def cost_resource!
    puts "cost resource: #{cost_resource}" if cost_resource
    ResourceService.new(@player.id, cost_resource).cost_resource!
    @player.reload
  end

  def draw_items
    case @card_pool_type
    when 'rare gem', 'epic gem' then draw_gems
    when 'hero' then draw_hero
    end
  end

  def draw_gems
    @count.times.map { draw_single_gem }
  end

  def draw_single_gem
    config = GEM_CONFIG[@card_pool_type]
    guarantee_field = config[:guarantee_gem_field]

    # 初始化抽卡次数记录
    @player.draw_times[guarantee_field] ||= 0

    # 确定宝石等级
    level = determine_gem_level(config, guarantee_field)

    # 创建宝石
    create_gemstone(level).tap do
      update_guarantee_counter(config, guarantee_field, level)
      @player.save!
    end
  end

  def determine_gem_level(config, guarantee_field)
    if guaranteed?(config, guarantee_field)
      config[:guarantee_gem_level]
    else
      calculate_random_level(config[:probability])
    end
  end

  def guaranteed?(config, field)
    @player.draw_times[field] == config[:guarantee_gem_count] - 1
  end

  def calculate_random_level(probability_table)
    rand_num = rand(0.0..100.0)
    probability_table.each do |p|
      rand_num -= p[:probability]
      return p[:level] if rand_num <= 0
    end
    2 # 默认等级
  end

  def update_guarantee_counter(config, field, level)
    if guaranteed?(config, field)
      @player.draw_times[field] = 0
    elsif level >= config[:guarantee_gem_level]
      @player.draw_times[field] = 0 # 抽到高级宝石重置保底
    else
      @player.draw_times[field] += 1
    end
  end

  def create_gemstone(level)
    Gemstone.generate(level, @player.id).tap(&:save!)
  end

  def determine_sidekick
    BaseSidekick.all.sample
  end

  def draw_single_hero
    config = GEM_CONFIG[@card_pool_type]
    sidekick = determine_sidekick
    probability_table = config[:probability] || CsvConfig.load_probability_hero
    probability_config = calculate_random_probability(probability_table)
    puts "Probability Config: #{probability_config[:type]}"
    item = probability_config[:type] == 'skb' ? sidekick.skill_book_icon : sidekick.fragment_name
    @player.add_item(item, probability_config[:count])
    { item => probability_config[:count] }
  end

  def calculate_random_probability(probability_table)
    rand_num = rand(0.0..100.0)
    probability_table.each do |p|
      rand_num -= p[:probability]
      return p if rand_num <= 0
    end
  end

  def draw_hero
    @count.times.map { draw_single_hero }.tap { @player.save! }
  end

  ##
  # Validate free claim eligibility for ad-based draws
  # @raise [ArgumentError] if player has reached daily free claim limit
  def validate_free_claim!
    initialize_free_claims_structure!

    # Map card pool type to free claims key
    pool_key = case @card_pool_type
               when 'hero' then 'hero'
               when 'rare gem' then 'rare'
               when 'epic gem' then 'epic'
               else raise ArgumentError, "Unknown card pool type: #{@card_pool_type}"
               end

    claim_data = @player.draw_times['free_claims'][pool_key]
    today = Date.today.to_s

    # Reset count if new day
    if claim_data['last_reset_date'] != today
      claim_data['count'] = 0
      claim_data['last_reset_date'] = today
    end

    # Check if limit reached
    limit = FREE_CLAIM_LIMITS[pool_key]
    if claim_data['count'] >= limit
      raise ArgumentError, "free claim limit reached for #{pool_key}"
    end
  end

  ##
  # Track a free claim in the player's draw_times
  def track_free_claim!
    initialize_free_claims_structure!

    # Map card pool type to free claims key
    pool_key = case @card_pool_type
               when 'hero' then 'hero'
               when 'rare gem' then 'rare'
               when 'epic gem' then 'epic'
               else raise ArgumentError, "Unknown card pool type: #{@card_pool_type}"
               end

    claim_data = @player.draw_times['free_claims'][pool_key]
    claim_data['count'] = (claim_data['count'] || 0) + 1
    @player.save!
  end

  ##
  # Ensure free_claims structure exists in draw_times
  def initialize_free_claims_structure!
    @player.draw_times ||= {}
    @player.draw_times['free_claims'] ||= {}

    # Initialize each pool type if not present
    ['hero', 'rare', 'epic'].each do |pool|
      @player.draw_times['free_claims'][pool] ||= {
        'count' => 0,
        'last_reset_date' => Date.today.to_s
      }
    end
  end
end
