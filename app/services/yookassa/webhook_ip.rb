module Yookassa
  module WebhookIp
    # https://yookassa.ru/developers/using-api/webhooks
    ALLOWED_CIDRS = [
      IPAddr.new("185.71.76.0/27"),
      IPAddr.new("185.71.77.0/27"),
      IPAddr.new("77.75.153.0/25"),
      IPAddr.new("77.75.156.11/32"),
      IPAddr.new("77.75.156.35/32"),
      IPAddr.new("2a02:5180::/32")
    ].freeze

    module_function

    def allowed?(ip_string)
      return true if Rails.env.development? || Rails.env.test?

      ip = IPAddr.new(ip_string)
      ALLOWED_CIDRS.any? { |range| range.include?(ip) }
    rescue IPAddr::InvalidAddressError
      false
    end
  end
end
