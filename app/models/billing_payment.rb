class BillingPayment < ApplicationRecord
  STATUSES = %w[pending waiting_for_capture succeeded canceled].freeze
  PURPOSES = %w[pro_initial pro_renewal].freeze

  attribute :metadata, :json

  belongs_to :user

  validates :yookassa_payment_id, presence: true, uniqueness: true
  validates :status, inclusion: { in: STATUSES }
  validates :purpose, inclusion: { in: PURPOSES }

  def succeeded?
    status == "succeeded"
  end

  def apply_remote_status!(remote_status)
    update!(status: remote_status) if STATUSES.include?(remote_status)
  end
end
