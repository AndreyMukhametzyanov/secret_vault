require "test_helper"

class PlanLimitsTest < ActiveSupport::TestCase
  test "free tier allows only 24h and one read" do
    assert_equal %w[24h], PlanLimits.allowed_expires_in_keys
    assert_equal [ 1 ], PlanLimits.allowed_max_reads_values
    assert_not PlanLimits.expires_in_enabled?("7d")
    assert_not PlanLimits.max_reads_enabled?(3)
  end

  test "resolve clamps disallowed choices on free tier" do
    freeze_time do
      at = PlanLimits.resolve_expires_at("7d")
      assert_in_delta 24.hours.from_now.to_i, at.to_i, 2

      assert_equal 1, PlanLimits.resolve_max_reads(5)
    end
  end
end
