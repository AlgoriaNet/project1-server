class GamingChannel < ApplicationCable::Channel
  def subscribed
    stream_from "Gaming_#{params[:user_id]}"
    Rails.logger.info("subscribed to gaming")
    Rails.logger.info(params)
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  def login(json)
    Rails.logger.info("login to gaming")
    Rails.logger.info(params)
    Rails.logger.info(json)
  end
end
