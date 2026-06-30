module Billing
  module ProPlan
    MONTHLY_AMOUNT_CENTS = 29_900

    module_function

    def amount_value
      format("%.2f", MONTHLY_AMOUNT_CENTS / 100.0)
    end

    def currency
      "RUB"
    end

    def period_duration
      1.month
    end
  end
end
