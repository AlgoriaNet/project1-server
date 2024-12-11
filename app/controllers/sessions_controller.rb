class SessionsController < ApplicationController
  skip_before_action :verify_authenticity_token
  require 'openssl'
  require 'base64'

  SECRET_KEY = "3QIVgamt6PhGPJ4EyK1VtCnpfAdp744I"

  # 登录方法
  def login
    Rails.logger.info params
    email = params[:email]
    password = params[:password]
    # 解密密码
    encrypted_password = Base64.decode64(password)  # 解码密码
    # 解密密码
    password = EncryptionService.decrypt_with_private_key(encrypted_password)

    user = User.find_by(email: email)

    if user&.authenticate(password)
      token = encode_jwt(user.id)
      render json: { token: token, user: { id: user.id, email: user.email } }, status: :ok
    else
      render json: { error: 'Invalid email or password' }, status: :unauthorized
    end
  end

  # 游客登录
  def guest_login
    user = User.create_guest_user
    token = encode_jwt(user.id)
    render json: { token: token, user: { id: user.id, email: user.email } }, status: :ok
  end

  private

  # 生成 JWT
  def encode_jwt(user_id)
    payload = { user_id: user_id, exp: 24.hours.from_now.to_i }
    JWT.encode(payload, Rails.application.secret_key_base)
  end
end
