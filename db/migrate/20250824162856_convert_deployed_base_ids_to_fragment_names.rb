class ConvertDeployedBaseIdsToFragmentNames < ActiveRecord::Migration[7.1]
  def up
    # Convert deployed_base_ids from numeric [6,5] to fragment_name ["06_Zhara","05_Lyanna"] format
    Player.where.not(deployed_base_ids: []).where.not(deployed_base_ids: "[]").each do |player|
      begin
        # Parse the JSON string to array
        base_ids_array = JSON.parse(player.deployed_base_ids)
        next if base_ids_array.empty?
        
        # Convert numeric base_ids to fragment_names
        fragment_names = base_ids_array.map do |base_id|
          base_sidekick = BaseSidekick.find_by(id: base_id)
          if base_sidekick
            base_sidekick.fragment_name
          else
            Rails.logger.warn "BaseSidekick not found for base_id: #{base_id}"
            nil
          end
        end.compact
        
        # Update player with fragment_name format
        player.update_column(:deployed_base_ids, fragment_names.to_json)
        Rails.logger.info "Player #{player.id}: #{base_ids_array} -> #{fragment_names}"
      rescue JSON::ParserError => e
        Rails.logger.error "Failed to parse deployed_base_ids for player #{player.id}: #{e.message}"
      end
    end
  end
  
  def down
    # Convert back from fragment_name ["06_Zhara","05_Lyanna"] to numeric [6,5] format
    Player.where.not(deployed_base_ids: []).where.not(deployed_base_ids: "[]").each do |player|
      begin
        # Parse the JSON string to array
        fragment_names_array = JSON.parse(player.deployed_base_ids)
        next if fragment_names_array.empty?
        
        # Convert fragment_names back to numeric base_ids
        base_ids = fragment_names_array.map do |fragment_name|
          base_sidekick = BaseSidekick.find_by(fragment_name: fragment_name)
          if base_sidekick
            base_sidekick.id
          else
            Rails.logger.warn "BaseSidekick not found for fragment_name: #{fragment_name}"
            nil
          end
        end.compact
        
        # Update player with numeric format
        player.update_column(:deployed_base_ids, base_ids.to_json)
        Rails.logger.info "Player #{player.id}: #{fragment_names_array} -> #{base_ids}"
      rescue JSON::ParserError => e
        Rails.logger.error "Failed to parse deployed_base_ids for player #{player.id}: #{e.message}"
      end
    end
  end
end
