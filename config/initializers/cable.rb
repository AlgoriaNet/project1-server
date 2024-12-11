Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # 开发环境中允许所有来源
    origins '*' if Rails.env.development?

    # 生产环境中只允许特定域名
    origins '*' if Rails.env.production?

    resource '*',
             headers: :any,
             methods: [:get, :post, :put, :delete, :options, :head, :WebSocket]
  end
end

Rails.application.configure do
  # 在开发环境中允许来自 localhost 的 WebSocket 连接
  config.action_cable.allowed_request_origins = ['*']
end
