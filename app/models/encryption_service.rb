class EncryptionService
  def self.public_key
    OpenSSL::PKey::RSA.new(Rails.application.credentials.rsa_public_key)
  end

  def self.private_key
    OpenSSL::PKey::RSA.new(File.read("#{Rails.root}/private_key.pem"))
  end

  # 公钥加密（用于前端加密）
  def self.encrypt_with_public_key(plain_text)
    public_key.public_encrypt(plain_text)
  end

  # 私钥解密（用于后端解密）
  def self.decrypt_with_private_key(encrypted_data)
    private_key.private_decrypt(encrypted_data)
  end
end
