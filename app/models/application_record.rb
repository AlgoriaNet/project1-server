class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  def snake_to_camel(snake_str)
    snake_str.split('_').map(&:capitalize).join
  end

  def as_ws_json(options = { only: [], except: [], include: [] })
    columns = self.class.column_names - %w[created_at updated_at]
    if options[:only].present?
      columns = columns & options[:only].map(&:to_s)
    else
      columns = columns - options[:except].map(&:to_s)
    end
    {}.tap do |h|
      columns.each { |k| h[snake_to_camel(k)] = self[k] }
      options[:include].each do |k|
        h[snake_to_camel(k)] = self.send(k).as_ws_json
      end
    end
  end
end
