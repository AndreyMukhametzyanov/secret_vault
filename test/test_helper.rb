ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

class ActiveSupport::TestCase
  parallelize(workers: :number_of_processors)

  setup do
    SecretVault::RedisClient.flushdb
  end
end

class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
end
