module Billing
  # Автоплатёж без redirect: payment_method_id из первой успешной оплаты.
  class RenewSubscription
    def self.call(subscription:, client: Yookassa::Client.new)
      new(subscription:, client:).call
    end

    def initialize(subscription:, client:)
      @subscription = subscription
      @client = client
    end

    def call
      return unless subscription.auto_renew?
      return if subscription.yookassa_payment_method_id.blank?
      return unless subscription.pro_entitled? && subscription.current_period_ends_at <= 1.day.from_now

      user = subscription.user
      idempotence_key = "renew-#{subscription.id}-#{subscription.current_period_ends_at.to_i}"
      body = {
        amount: {
          value: Billing::ProPlan.amount_value,
          currency: Billing::ProPlan.currency
        },
        capture: true,
        payment_method_id: subscription.yookassa_payment_method_id,
        description: I18n.t("billing.renewal.payment_description"),
        metadata: {
          user_id: user.id.to_s,
          purpose: "pro_renewal",
          subscription_id: subscription.id.to_s
        }
      }

      remote = client.create_payment(idempotence_key:, body:)
      user.billing_payments.create!(
        yookassa_payment_id: remote.fetch("id"),
        amount_cents: Billing::ProPlan.amount_cents,
        currency: Billing::ProPlan.currency,
        status: remote["status"].presence || "pending",
        purpose: "pro_renewal",
        metadata: body[:metadata]
      )
    end

    private

    attr_reader :subscription, :client
  end
end
