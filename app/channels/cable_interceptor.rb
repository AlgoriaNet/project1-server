class CableInterceptor < ActionCable::Server::Base
  def self.receive_message(subscription, data)
    Rails.logger.info "Received #{data}"
    # 可以在这里对数据进行检查或修改
    if data['sign'].blank?
      subscription.transmit({ error: 'sign cannot be empty' })
    end
    encrypted_sign = Base64.decode64(data['sign'])
    sign_decrypt = EncryptionService.decrypt_with_private_key(encrypted_sign)
    if sign_decrypt != data['data']
      subscription.transmit({ error: "sign is error" })
    end
  end
end
