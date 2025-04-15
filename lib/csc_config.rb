# frozen_string_literal: true

class CscConfig
  TYPE_MAPPINGS = {
    'int' => ->(value) { value.to_i },
    'float' => ->(value) { value.to_f },
    'string' => ->(value) { value },
    'bool' => ->(value) { value.downcase == 'true' },
  }

  class << self
    def load_by_path(file_name)
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

    def load_generic_gemstone_box
      load_by_path 'generic_gemstone_box.csv'
    end

    def load_unusual_gemstone_box
      load_by_path 'unusual_gemstone_box.csv'
    end

    def load_base_equipment
      load_by_path 'base_equipment.csv'
    end

    def load_washing_config
      load_by_path 'washing_config.csv'
    end
  end
end
