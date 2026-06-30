ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

class ActiveSupport::TestCase
  parallelize(workers: :number_of_processors)

  setup do
    SecretVault::RedisClient.flushdb
  end

  def stub_singleton(klass, method, value)
    original = klass.method(method)
    klass.define_singleton_method(method) { |*_args, **_kwargs| value }
    yield
  ensure
    klass.define_singleton_method(method, original)
  end
end

class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
end
