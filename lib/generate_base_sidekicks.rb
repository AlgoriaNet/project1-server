class GenerateBaseSidekicks
  require 'csv_config'

  # This method clears the existing base items and loads new ones from the CSV configuration.
  # It iterates through each base equipment defined in the CSV and creates a BaseItem record.
  #
  # @return [void]
  def self.generate
    puts "Generating BaseSidekicks from CSV..."
    BaseSidekick.destroy_all
    puts "Cleared existing BaseSidekicks"
    
    created_count = 0
    CsvConfig.load_base_sidekicks.each do |base_sidekick|
      sk = BaseSidekick.create(base_sidekick)
      puts "Created #{sk.name}: skill_id=#{sk.skill_id}"
      created_count += 1
    end
    puts "Successfully created #{created_count} BaseSidekicks"
  end
end
