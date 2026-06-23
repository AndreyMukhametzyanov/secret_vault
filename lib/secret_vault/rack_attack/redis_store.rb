module SecretVault
  module RackAttack
    class RedisStore
      PREFIX = "rack_attack:"

      def initialize(redis = SecretVault::RedisClient.connection)
        @redis = redis
      end

      def read(key)
        @redis.get("#{PREFIX}#{key}")
      end

      def write(key, value, **options)
        ex = options[:expires_in]&.to_i
        if ex
          @redis.set("#{PREFIX}#{key}", value, ex: ex)
        else
          @redis.set("#{PREFIX}#{key}", value)
        end
      end

      def increment(key, amount = 1, **options)
        full = "#{PREFIX}#{key}"
        value = @redis.incrby(full, amount)
        if options[:expires_in]
          @redis.expire(full, options[:expires_in].to_i) if value == amount
        end
        value
      end
    end
  end
end
