class BaseItem < ApplicationRecord
  def self.exists?(id_or_name)
    if id_or_name.class == Integer
      id = id_or_name.to_i
      where(id: id).exists?
    else
      where(name: id_or_name).exists?
    end
  end

  def self.find(id_or_name)
    if id_or_name.class == Integer
      id = id_or_name.to_i
      return nil unless where(id: id).exists?
      find_by(id: id)
    else
      find_by(name: id_or_name)
    end
  end

  def self.get_name(id_or_name)
    item = find(id_or_name)
    return nil unless item
    item.name
  end

  def self.get_id(id_or_name)
    item = find(id_or_name)
    return nil unless item
    item.id
  end
end
