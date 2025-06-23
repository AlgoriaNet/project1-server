class User < ApplicationRecord
  has_secure_password
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, presence: true, length: { minimum: 6 }, if: :password_digest_changed?


  def self.create_guest_user(device_id)

    create!(
      email: "guest_#{SecureRandom.uuid}@example.com",
      password: SecureRandom.hex(8),
    )
  end
end
