require "test_helper"

class Secrets::CreateRateLimitTest < ActiveSupport::TestCase
  test "allows up to daily limit then blocks" do
    ip = "198.51.100.42"

    Secrets::CreateRateLimit::DAILY_LIMIT.times do
      assert Secrets::CreateRateLimit.allowed?(ip)
      Secrets::CreateRateLimit.record!(ip)
    end

    assert_not Secrets::CreateRateLimit.allowed?(ip)
  end
end
