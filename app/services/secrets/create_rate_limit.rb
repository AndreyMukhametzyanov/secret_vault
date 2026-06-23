module Secrets
  class CreateRateLimit
    DAILY_LIMIT = 10

    def self.allowed?(ip)
      return true if ip.blank?

      SecretVault::RedisClient.get(cache_key(ip)).to_i < DAILY_LIMIT
    end

    def self.record!(ip)
      return if ip.blank?

      SecretVault::RedisClient.incr(cache_key(ip), expires_in: 25.hours)
    end

    def self.cache_key(ip)
      "secrets:create:#{ip}:#{Date.current}"
    end
  end
end
