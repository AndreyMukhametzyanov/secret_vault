class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :created_secrets, class_name: "Secret", foreign_key: :creator_user_id, dependent: :nullify, inverse_of: :creator_user

  def pro?
    false
  end
end
