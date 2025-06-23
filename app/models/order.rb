# frozen_string_literal: true

class Order < ApplicationRecord
  has_one :player
  before_create :set_order_id

  validates :product_id, presence: true
  validates :platform, presence: true
  validates :status, presence: true, inclusion: { in: %w[pending paid delivered failed refunded] }

  enum status: { pending: 'pending', paid: 'paid', delivered: 'delivered', failed: 'failed', refunded: 'refunded' }

  scope :by_player_and_platform, ->(player_id, platform) {
    where(player_id: player_id, platform: platform)
  }

  scope :recent, ->(limit = 10) {
    order(created_at: :desc).limit(limit)
  }

  def set_order_id
    self.order_id ||= SecureRandom.uuid
  end
end
