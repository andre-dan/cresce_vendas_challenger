class User < ApplicationRecord
  has_secure_password

  has_many :stores

  validates :code, :api_credential, presence: true, uniqueness: true
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
end
