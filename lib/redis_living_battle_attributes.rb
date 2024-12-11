# lib/redis_living_attributes.rb
module RedisLivingBattleAttributes
  extend ActiveSupport::Concern

  included do
    # 初始化Redis连接
    redis = Redis.new(url: ENV['REDIS_URL'] || 'redis://localhost:6379/0')

    # 定义Redis命名空间（可选）
    REDIS_NAMESPACE = 'living_battle_attributes:'

    # 封装Redis连接
    def redis
      redis ||= Redis.new(url: ENV['REDIS_URL'] || 'redis://localhost:6379/0')
    end
  end

  # 读取用户属性
  def attributes
    redis_hash = redis.hgetall("#{REDIS_NAMESPACE}:#{self.Class}:#{id}")
    redis_hash.transform_keys!(&:to_sym).symbolize_keys! if redis_hash.is_a?(Hash)
    redis_hash || {}
  end

  # 设置用户属性
  def update_attributes(attrs)
    redis.pipelined do
      attrs.each do |key, value|
        redis.hset("#{REDIS_NAMESPACE}#{id}", key.to_s, value.to_s)
      end
    end
  end

  # 读取单个属性
  def read_attribute(name)
    redis.hget("#{REDIS_NAMESPACE}#{id}", name.to_s)
  end

  # 设置单个属性
  def write_attribute(name, value)
    redis.hset("#{REDIS_NAMESPACE}#{id}", name.to_s, value.to_s)
  end

  # 为了方便，你可以定义一些方法来直接访问常见属性
  def name
    read_attribute('name')
  end

  def name=(value)
    write_attribute('name', value)
  end

  # ... 为其他属性添加类似的方法，或者根据需要扩展
end
