module Billing
  module ProPlan
    DEFAULT_MONTHLY_AMOUNT_RUB = 299

    module_function

    def monthly_amount_rub
      raw = ENV.fetch("PRO_MONTHLY_AMOUNT_RUB", DEFAULT_MONTHLY_AMOUNT_RUB.to_s)
      Integer(raw)
    rescue ArgumentError, TypeError
      DEFAULT_MONTHLY_AMOUNT_RUB
    end

    def amount_value
      format("%.2f", monthly_amount_rub)
    end

    def amount_cents
      monthly_amount_rub * 100
    end

    def currency
      ENV.fetch("PRO_CURRENCY", "RUB")
    end

    def period_duration
      1.month
    end
  end
end
