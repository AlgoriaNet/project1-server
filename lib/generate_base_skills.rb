require 'csv'

class GenerateBaseSkills
  def self.generate
    puts "Generating BaseSkills from CSV..."
    
    # Clear existing data with dependencies
    BaseSkillLevelUpEffect.destroy_all
    puts "Cleared existing BaseSkillLevelUpEffects"
    BaseSkill.destroy_all
    puts "Cleared existing BaseSkills"
    
    # Path to CSV file
    csv_file_path = Rails.root.join('lib', 'config', 'base_skills.csv')
    
    unless File.exist?(csv_file_path)
      puts "ERROR: #{csv_file_path} not found!"
      return
    end
    
    # Read and process CSV
    created_count = 0
    
    CSV.foreach(csv_file_path, headers: true, skip_blanks: true) do |row|
      next if row['id'] == 'int' # Skip type definition row
      
      begin
        # Parse JSON fields
        active_character = row['active_character'].present? ? JSON.parse(row['active_character']) : {}
        
        skill = BaseSkill.create!(
          id: row['id'].to_i,
          name: row['name'],
          icon: row['icon'],
          cd: row['cd'].to_f,
          duration: row['duration'].to_f,
          max_angle: row['max_angle'].to_i,
          damage_ratio: row['damage_ratio'].to_f,
          two_stage_damage_ratio: row['two_stage_damage_ratio'].to_f,
          three_stage_damage_ratio: row['three_stage_damage_ratio'].to_f,
          speed: row['speed'].to_f,
          scope: row['scope'].to_f,
          split_count: row['split_count'].to_i,
          release_ultimate_count: row['release_ultimate_count'].to_i,
          release_count: row['release_count'].to_i,
          launches_count: row['launches_count'].to_i,
          launches_interval: row['launches_interval'].to_f,
          destroy_delay: row['destroy_delay'].to_f,
          is_dynamic: row['is_dynamic'] == 'true',
          is_living_position_release: row['is_living_position_release'] == 'true',
          is_impenetrability: row['is_impenetrability'] == 'true',
          is_trace_monster: row['is_trace_monster'] == 'true',
          is_cd_rest_by_released: row['is_cd_rest_by_released'] == 'true',
          damage_type: row['damage_type'],
          skill_target_type: row['skill_target_type'],
          active_character: active_character,
          description: row['description']
        )
        
        created_count += 1
        puts "Created skill: #{skill.name} (ID: #{skill.id})"
        
      rescue StandardError => e
        puts "ERROR creating skill from row #{row['id']}: #{e.message}"
        puts "Row data: #{row.to_h}"
      end
    end
    
    puts "Successfully created #{created_count} BaseSkills"
    puts "Total BaseSkills in database: #{BaseSkill.count}"
  end
end

# Run if called directly
if __FILE__ == $0
  GenerateBaseSkills.generate
end