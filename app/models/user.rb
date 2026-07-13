class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :created_secrets, class_name: "Secret", foreign_key: :creator_user_id, dependent: :nullify, inverse_of: :creator_user
  has_one :subscription, dependent: :destroy
  has_many :billing_payments, dependent: :destroy

  def pro?
    return true if SecretVault::Deployment.licensed_pro?

    subscription&.pro_entitled?
  end

  validate :mask_duplicate_email_on_signup, on: :create

  def can_manage_branding?
    SecretVault::Deployment.on_prem? && admin?
  end

  private

  def mask_duplicate_email_on_signup
    return unless errors.of_kind?(:email, :taken)

    errors.delete(:email, :taken)
    errors.add(:base, I18n.t("devise.registrations.email_unavailable"))
  end
end
