module Billing
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
