# frozen_string_literal: true

class BaseEquipment < ApplicationRecord
  PARTS = [:Shoulder, :Chest, :Helm, :Gloves, :Pants, :Boots]
  def as_ws_json(options = nil)
    super({except: [:id, :created_at, :updated_at]})
  end
end
