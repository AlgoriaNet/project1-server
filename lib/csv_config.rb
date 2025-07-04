# frozen_string_literal: true

class CsvConfig
  TYPE_MAPPINGS = {
    'int' => ->(value) { value.to_i },
    'float' => ->(value) { value.to_f },
    'string' => ->(value) { value },
    'bool' => ->(value) { value.downcase == 'true' },
    'json' => ->(value) { JSON.parse(value.gsub(';', ',').gsub("\'", "\"")) rescue value },
  }

  def self.load_by_path(file_name)
    path = Rails.root.join('lib/config', file_name)
    result_array = []
    head = []
    types = []

    CSV.readlines(path).each_with_index do |line, line_num|
      if line_num == 0
        head = line
      elsif line_num == 1
        types = line
      else
        data = line
        next if data.size != head.size || data.size != types.size
        data_hash = {}
        data.each_with_index do |value, index|
          type_string = types[index].strip.downcase
          converter = TYPE_MAPPINGS[type_string] || ->(value) { value.to_s }
          data_hash[head[index].strip.to_sym] = converter.call(value)
        end
        result_array << data_hash
      end
    end
    result_array
  end

  class << self
    def load_rare_gem
      load_by_path 'probability_rare_gem.csv'
    end

    def load_epic_gem
      load_by_path 'probability_epic_gem.csv'
    end

    def load_probability_hero
      load_by_path 'probability_hero.csv'
    end

    def load_base_equipment
      load_by_path 'base_equipment.csv'
    end

    def load_washing_config
      load_by_path 'washing_config.csv'
    end

    def load_base_items
      load_by_path 'base_items.csv'
    end

    def load_products
      load_by_path 'product.csv'
    end

    def load_draw_cost
      load_by_path 'draw_cost.csv'
    end

    def load_base_sidekicks
      load_by_path 'base_sidekicks.csv'
    end
  end
end
