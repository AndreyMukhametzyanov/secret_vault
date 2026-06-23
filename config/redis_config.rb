module SecretVault
  module RedisConfig
    DEFAULT_HOST = "127.0.0.1"
    DEFAULT_PORT = 6379

    def self.cache_url
      return ENV["REDIS_URL"] if ENV["REDIS_URL"].present?

      if Rails.env.production?
        raise KeyError, "REDIS_URL must be set in production"
      end

      db = { "development" => 0, "test" => 1 }.fetch(Rails.env, 0)
      "redis://#{DEFAULT_HOST}:#{DEFAULT_PORT}/#{db}"
    end
  end
end
