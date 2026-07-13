module Webhooks
  # ЮKassa → perform_later ProcessYookassaNotificationJob (Pro включается там, не на billing/return).
  class YookassaController < ApplicationController
    skip_before_action :verify_authenticity_token

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
  end
end
