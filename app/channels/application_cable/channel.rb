module ApplicationCable
  class Channel < ActionCable::Channel::Base
    def stream_name
      "#{self.class.name.gsub("Channel", "")}_#{params[:user_id]}"
    end

    def receive(data)
      Rails.logger.info "Received #{data}"
      # 可以在这里对数据进行检查或修改
      reject if data['sign'].blank?
      encrypted_sign = Base64.decode64(data['sign'])
      sign_decrypt = EncryptionService.decrypt_with_private_key(encrypted_sign)
      reject if data['json'].present? && sign_decrypt != data['json']
      reject if data['json'].blank? && sign_decrypt != data['action'] + params["user_id"]
    end

    def player
      begin
        @player ||= Player.find(params[:user_id])
      rescue ActiveRecord::RecordNotFound
        render_error "error", {}, "Player not found", 404
      end
    end

    def subscribed
      @player = Player.find(params[:user_id])
      @player_id = @player.id
      stream_from stream_name
    end

    def render_response(action, json, data)
      ActionCable.server.broadcast(stream_name, {action: action, code: 200, requestId: json["requestId"], data: data})
    end

    def render_notification(action, data)
      ActionCable.server.broadcast(stream_name, {action: action, code: 200, data: data})
    end

    def render_error(action, json, msg, code = 500)
      ActionCable.server.broadcast(stream_name, {action: action, code: code, requestId: json["requestId"], data: {msg: msg}})
    end
  end
end
