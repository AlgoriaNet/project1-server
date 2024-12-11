module ApplicationCable
  class Channel < ActionCable::Channel::Base
    def receive(data)
      Rails.logger.info "Received #{data}"
      # 可以在这里对数据进行检查或修改
      reject if data['sign'].blank?
      encrypted_sign = Base64.decode64(data['sign'])
      sign_decrypt = EncryptionService.decrypt_with_private_key(encrypted_sign)
      reject if data['json'].present? && sign_decrypt != data['json']
      reject if data['json'].blank? && sign_decrypt != data['action'] + params["user_id"]
    end
  end
end
