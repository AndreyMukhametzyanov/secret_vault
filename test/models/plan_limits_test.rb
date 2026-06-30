require "test_helper"

class PlanLimitsTest < ActiveSupport::TestCase
  test "for nil or free user applies free tier" do
    user = User.new(email: "free@example.com")

    [ nil, user ].each do |account|
      limits = PlanLimits.for(account)
      assert_equal :free, limits.tier
      assert_not limits.pro?
      assert_equal %w[24h], limits.allowed_expires_in_keys
      assert_equal [ 1 ], limits.allowed_max_reads_values
      assert_not limits.expires_in_enabled?("7d")
      assert_not limits.max_reads_enabled?(3)
    end
  end

  test "free tier resolve clamps disallowed choices" do
    limits = PlanLimits.for(nil)

    freeze_time do
      at = limits.resolve_expires_at("7d")
      assert_in_delta 24.hours.from_now.to_i, at.to_i, 2

      assert_equal 1, limits.resolve_max_reads(5)
    end
  end

  test "pro account allows extended ttl and reads" do
    pro_user = User.create!(email: "pro@example.com", password: "password123")
    pro_user.create_subscription!(status: "active", current_period_ends_at: 1.month.from_now)

    limits = PlanLimits.for(pro_user)
    assert limits.pro?
    assert_equal PlanLimits::PRO_EXPIRES_IN_KEYS, limits.allowed_expires_in_keys
    assert_equal "24h", limits.default_expires_in_key
    assert_equal PlanLimits::MAX_READS_CHOICES, limits.allowed_max_reads_values

    freeze_time do
      at = limits.resolve_expires_at("7d")
      assert_in_delta 7.days.from_now.to_i, at.to_i, 2
      assert_equal 3, limits.resolve_max_reads(3)
      assert_equal 5, limits.resolve_max_reads(5)
    end
  end
end
