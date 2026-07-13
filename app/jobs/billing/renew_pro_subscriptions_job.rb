module Billing
  # Запускать по cron в production (например раз в час).
  # Находит подписки с auto_renew и инициирует списание через RenewSubscription;
  # продление периода — снова webhook payment.succeeded.
  class RenewProSubscriptionsJob < ApplicationJob
    queue_as :default

    def perform
      return unless Yookassa::Configuration.configured?

      Subscription.renewable.find_each do |subscription|
        Billing::RenewSubscription.call(subscription:)
      rescue Yookassa::Client::Error => e
        Rails.logger.error("[RenewProSubscriptionsJob] subscription=#{subscription.id} #{e.message}")
      end
    end
  end
end
