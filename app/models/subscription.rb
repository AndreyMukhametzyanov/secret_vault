class Subscription < ApplicationRecord
  STATUSES = %w[pending active past_due canceled].freeze

  belongs_to :user

  validates :status, inclusion: { in: STATUSES }

  scope :renewable, lambda {
    where(status: "active", auto_renew: true)
      .where.not(yookassa_payment_method_id: nil)
      .where(current_period_ends_at: ..1.day.from_now)
  }

  def pro_entitled?
    current_period_ends_at.present? && current_period_ends_at.future?
  end

  def active_subscription?
    status == "active" && pro_entitled?
  end

  def cancel_auto_renew!
    update!(auto_renew: false, canceled_at: Time.current)
  end

  def extend_period!(duration = 1.month)
    base = [ current_period_ends_at, Time.current ].compact.max
    update!(
      status: "active",
      current_period_ends_at: base + duration,
      canceled_at: nil,
      auto_renew: true
    )
  end
end
