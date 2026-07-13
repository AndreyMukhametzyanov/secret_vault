module Billing
  # Вызывается из ProcessYookassaNotificationJob после webhook ЮKassa.
  class ProcessPaymentNotification
    def self.call(event:, payment_object:, client: Yookassa::Client.new)
      new(event:, payment_object:, client:).call
    end

    def initialize(event:, payment_object:, client:)
      @event = event
      @payment_object = payment_object
      @client = client
    end

    def call
      payment_id = payment_object["id"]
      return if payment_id.blank?

      remote = verify_remote_payment(payment_id)
      return if remote.blank?

      billing_payment = BillingPayment.find_by(yookassa_payment_id: payment_id)
      return if billing_payment.blank?

      case event
      when "payment.succeeded"
        handle_succeeded(billing_payment, remote)
      when "payment.canceled"
        handle_canceled(billing_payment, remote)
      else
        billing_payment.apply_remote_status!(remote["status"])
      end
    end

    private

    attr_reader :event, :payment_object, :client

    def verify_remote_payment(payment_id)
      return payment_object unless Yookassa::Configuration.configured?

      client.fetch_payment(payment_id)
    rescue Yookassa::Client::Error
      payment_object
    end

    def handle_succeeded(billing_payment, remote)
      return if billing_payment.succeeded?

      user = billing_payment.user
      subscription = user.subscription || user.create_subscription!(status: "pending")

      payment_method = remote["payment_method"] || {}
      if payment_method["saved"] && payment_method["id"].present?
        subscription.update!(yookassa_payment_method_id: payment_method["id"])
      end

      billing_payment.update!(status: "succeeded")
      subscription.extend_period!(Billing::ProPlan.period_duration)
    end

    def handle_canceled(billing_payment, remote)
      billing_payment.update!(status: "canceled", metadata: safe_metadata(remote["metadata"]))

      user = billing_payment.user
      subscription = user.subscription
      return unless subscription
      return unless billing_payment.purpose == "pro_renewal"

      subscription.update!(status: "past_due") if subscription.pro_entitled?
    end

    def safe_metadata(value)
      return if value.blank?

      JSON.parse(value.to_json)
    end
  end
end
