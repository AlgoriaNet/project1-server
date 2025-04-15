class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  def snake_to_camel(snake_str)
    snake_str.split('_').map(&:capitalize).join
  end

  def as_ws_json(options = nil)
    as_json(options)
  end
end
