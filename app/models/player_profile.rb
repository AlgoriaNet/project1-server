# frozen_string_literal: true

class PlayerProfile
  def initialize(player_id)
    @player_id = player_id
    @player = Player.find(player_id)
  end

  def draw_costs
    draw_costs = CsvConfig.load_draw_cost
    
    # Group by card_pool_type and consume_item=diamond
    diamond_costs = draw_costs.select { |cost| cost[:consume_item] == 'diamond' }
    
    {
      hero: {
        x1: diamond_costs.find { |c| c[:card_pool_type] == 'hero' && c[:count] == 1 }&.dig(:cost, 'diamond') || 300,
        x10: diamond_costs.find { |c| c[:card_pool_type] == 'hero' && c[:count] == 10 }&.dig(:cost, 'diamond') || 3000
      },
      rare: {
        x1: diamond_costs.find { |c| c[:card_pool_type] == 'rare gem' && c[:count] == 1 }&.dig(:cost, 'diamond') || 180,
        x10: diamond_costs.find { |c| c[:card_pool_type] == 'rare gem' && c[:count] == 10 }&.dig(:cost, 'diamond') || 1800
      },
      epic: {
        x1: diamond_costs.find { |c| c[:card_pool_type] == 'epic gem' && c[:count] == 1 }&.dig(:cost, 'diamond') || 200,
        x10: diamond_costs.find { |c| c[:card_pool_type] == 'epic gem' && c[:count] == 10 }&.dig(:cost, 'diamond') || 2000
      }
    }
  end

  def as_ws_json
    Rails.logger.info "[Perf] PlayerProfile#as_ws_json START at #{Time.now.to_f}"

    # CRITICAL: Reload player data to ensure fresh data for items like heroKey, rareKey, epicKey
    @player.reload
    player_data = @player.as_ws_json

    # CRITICAL: Use uncached queries to ensure fresh data after deployment mutations
    Rails.logger.info "[Perf] [as_ws_json] equipments start: #{Time.now.to_f}"
    equipments = Equipment.includes(:base_equipment, :gemstones).where(player_id: @player_id).map(&:as_ws_json)
    Rails.logger.info "[Perf] [as_ws_json] equipments end: #{Time.now.to_f}"

    Rails.logger.info "[Perf] [as_ws_json] gemstones start: #{Time.now.to_f}"
    gemstones = Gemstone.includes(:gemstone_entry, :secondary_gemstone_entry).where(player_id: @player_id).map(&:as_ws_json)
    Rails.logger.info "[Perf] [as_ws_json] gemstones end: #{Time.now.to_f}"

    Rails.logger.info "[Perf] [as_ws_json] sidekicks start: #{Time.now.to_f}"
    sidekicks = Sidekick.includes(base_sidekick: :base_skill).where(player_id: @player_id).map(&:as_ws_json)
    Rails.logger.info "[Perf] [as_ws_json] sidekicks end: #{Time.now.to_f}"

    Rails.logger.info "[Perf] [as_ws_json] draw_costs start: #{Time.now.to_f}"
    costs = draw_costs
    Rails.logger.info "[Perf] [as_ws_json] draw_costs end: #{Time.now.to_f}"

    result = ActiveRecord::Base.uncached do
      {
        Player: player_data.merge({
                                   equipments: equipments,
                                   gemstones: gemstones,
                                   sidekicks: sidekicks,
                                   draw_costs: costs,
                                 }),
      }
    end

    Rails.logger.info "[Perf] PlayerProfile#as_ws_json END at #{Time.now.to_f}"
    result
  end
end
