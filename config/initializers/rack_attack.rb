class Rack::Attack
  REVEAL_PATH = %r{\A/secrets/[^/]+/reveal\z}.freeze
  SHOW_PATH = %r{\A/secrets/[^/]+\z}.freeze

  throttle("secrets/create/ip", limit: 30, period: 1.hour) do |req|
    req.ip if req.post? && req.path == "/secrets"
  end

  throttle("secrets/reveal/ip", limit: 60, period: 1.hour) do |req|
    req.ip if req.post? && req.path.match?(REVEAL_PATH)
  end

  throttle("secrets/show/ip", limit: 120, period: 15.minutes) do |req|
    req.ip if req.get? && req.path.match?(SHOW_PATH) && !req.path.end_with?("/success")
  end

  self.throttled_responder = lambda do |_req|
    [ 429, { "Content-Type" => "text/plain; charset=utf-8" }, [ "Too many requests\n" ] ]
  end
end

Rails.application.config.after_initialize do
  Rack::Attack.enabled = !Rails.env.test?
  Rack::Attack.cache.store = SecretVault::RackAttack::RedisStore.new
end
