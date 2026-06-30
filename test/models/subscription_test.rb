require "test_helper"

class SubscriptionTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(email: "sub@example.com", password: "password123")
    @subscription = @user.create_subscription!(status: "active", current_period_ends_at: 10.days.from_now)
  end

  test "extend_period adds one month from max of now and current end" do
    freeze_time do
      @subscription.extend_period!
      assert_in_delta (10.days.from_now + 1.month).to_i, @subscription.current_period_ends_at.to_i, 2
    end
  end

  test "cancel_auto_renew keeps pro until period ends" do
    @subscription.cancel_auto_renew!
    assert_not @subscription.auto_renew?
    assert @subscription.pro_entitled?
    assert @user.pro?
  end
end
