module Billing
  class ProcessYookassaNotificationJob < ApplicationJob
    queue_as :default

    def perform(event:, payment_object:)
      Billing::ProcessPaymentNotification.call(event:, payment_object:)
    end
  end
end
