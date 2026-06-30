module Billing
  class Checkout
    class NotConfigured < StandardError; end

    Result = Data.define(:confirmation_url, :payment_id)

    def self.call(user:, purpose: "pro_initial", client: Yookassa::Client.new)
      new(user:, purpose:, client:).call
    end

    def initialize(user:, purpose:, client:)
      @user = user
      @purpose = purpose
      @client = client
    end

    def call
      raise NotConfigured unless Yookassa::Configuration.configured?

      subscription = user.subscription || user.create_subscription!(status: "pending")
      idempotence_key = SecureRandom.uuid
      body = payment_body(subscription)

      remote = client.create_payment(idempotence_key:, body:)
      payment_id = remote.fetch("id")
      confirmation_url = remote.dig("confirmation", "confirmation_url")

      if confirmation_url.blank?
        raise Yookassa::Client::Error, "Missing confirmation_url in YooKassa response"
      end

      user.billing_payments.create!(
        yookassa_payment_id: payment_id,
        amount_cents: Billing::ProPlan::MONTHLY_AMOUNT_CENTS,
        currency: Billing::ProPlan.currency,
        status: remote["status"].presence || "pending",
        purpose: purpose,
        metadata: body[:metadata]
      )

      Result.new(confirmation_url:, payment_id:)
    end

    private

    attr_reader :user, :purpose, :client

    def payment_body(subscription)
      {
        amount: {
          value: Billing::ProPlan.amount_value,
          currency: Billing::ProPlan.currency
        },
        capture: true,
        save_payment_method: true,
        confirmation: {
          type: "redirect",
          return_url: Yookassa::Configuration.return_url
        },
        description: I18n.t("billing.checkout.payment_description"),
        metadata: {
          user_id: user.id.to_s,
          purpose: purpose,
          subscription_id: subscription.id.to_s
        }
      }
    end
  end
end
