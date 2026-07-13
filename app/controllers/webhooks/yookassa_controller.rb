module Webhooks
  class YookassaController < ApplicationController
    skip_before_action :verify_authenticity_token
    before_action :ensure_saas_billing!

    def create
      unless Yookassa::WebhookIp.allowed?(request.remote_ip)
        head :forbidden
        return
      end

      payload = JSON.parse(request.body.read)
      event = payload["event"]
      payment_object = payload["object"]

      if event.blank? || payment_object.blank?
        head :bad_request
        return
      end

      Billing::ProcessYookassaNotificationJob.perform_later(event:, payment_object:)
      head :ok
    rescue JSON::ParserError
      head :bad_request
    end

    private

    def ensure_saas_billing!
      head :not_found unless SecretVault::Deployment.billing_enabled?
    end
  end
end
