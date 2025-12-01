class InitializeFreeGachaClaims < ActiveRecord::Migration[7.1]
  def up
    # Ensure all existing players have proper free_claims structure in draw_times
    Player.find_each do |player|
      player.draw_times ||= {}

      # Initialize free_claims tracking if not present
      unless player.draw_times['free_claims']
        player.draw_times['free_claims'] = {
          'hero' => { 'count' => 0, 'last_reset_date' => Date.today.to_s },
          'rare' => { 'count' => 0, 'last_reset_date' => Date.today.to_s },
          'epic' => { 'count' => 0, 'last_reset_date' => Date.today.to_s }
        }
        player.save(touch: false)
      end
    end
  end

  def down
    # Rollback: remove free_claims from all players
    Player.find_each do |player|
      player.draw_times.delete('free_claims') if player.draw_times.is_a?(Hash)
      player.save(touch: false)
    end
  end
end
