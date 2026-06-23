require_relative "boot"

require "rails/all"

Bundler.require(*Rails.groups)

require_relative "redis_config"

module SecretVault
  class Application < Rails::Application
    config.load_defaults 7.0
    config.autoload_lib(ignore: %w[assets tasks])

    config.i18n.default_locale = :ru
    config.i18n.available_locales = %i[ru en]
    config.i18n.fallbacks = [ :en ]

    config.middleware.use Rack::Attack
  end
end
