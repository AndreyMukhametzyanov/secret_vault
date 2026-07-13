module SecretVault
  module Deployment
    MODES = %w[saas on_prem].freeze

    module_function

    def mode
      raw = ENV.fetch("DEPLOYMENT_MODE", "saas").to_s.downcase
      MODES.include?(raw) ? raw : "saas"
    end

    def saas?
      mode == "saas"
    end

    def on_prem?
      mode == "on_prem"
    end

  # On-prem: Pro for all users without ЮKassa (self-hosted / contract).
    def licensed_pro?
      on_prem? && ActiveModel::Type::Boolean.new.cast(ENV.fetch("ON_PREM_LICENSED_PRO", "true"))
    end

    def billing_enabled?
      saas?
    end

    def sales_contact_email
      ENV["ON_PREM_SALES_EMAIL"].presence || "sales@example.com"
    end
  end
end
