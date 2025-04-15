class GamingChannel < ApplicationCable::Channel

  def login(json)
    Rails.logger.info("login to gaming")
    Rails.logger.info(params)
    Rails.logger.info(json)
  end
end
