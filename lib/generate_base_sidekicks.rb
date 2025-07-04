class GenerateBaseSidekicks
  require 'csv_config'

  # This method clears the existing base items and loads new ones from the CSV configuration.
  # It iterates through each base equipment defined in the CSV and creates a BaseItem record.
  #
  # @return [void]
  def self.generate
    BaseSidekick.destroy_all
    CsvConfig.load_base_sidekicks.each do |base_sidekick|
      BaseSidekick.create(base_sidekick)
    end
  end
end
