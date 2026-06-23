module SecretVault
  module RedisClient
    KEY_PREFIX = "secret_vault:"

    class << self
      def connection
        @connection ||= ::Redis.new(url: RedisConfig.cache_url)
      end

      def get(key)
        connection.get(prefixed(key))
      end

      def set(key, value, expires_in: nil)
        connection.set(prefixed(key), value, ex: expires_in&.to_i)
      end

      def incr(key, expires_in: nil)
        full = prefixed(key)
        value = connection.incr(full)
        connection.expire(full, expires_in.to_i) if expires_in && value == 1
        value
      end

      def del(key)
        connection.del(prefixed(key))
      end

      def flushdb
        connection.flushdb
      end

      private

      def prefixed(key)
        "#{KEY_PREFIX}#{key}"
      end
    end
  end
end
