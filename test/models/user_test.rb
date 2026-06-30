require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "pro? is false without active subscription period" do
    user = User.create!(email: "free@example.com", password: "password123")
    assert_not user.pro?

    user.create_subscription!(status: "active", current_period_ends_at: 1.day.ago)
    assert_not user.pro?
  end

  test "pro? is true when subscription period is in the future" do
    user = User.create!(email: "pro@example.com", password: "password123")
    user.create_subscription!(status: "active", current_period_ends_at: 1.month.from_now)

    assert user.pro?
  end

  test "rejects email without a dotted domain" do
    user = User.new(email: "www@ww", password: "password123", password_confirmation: "password123")
    assert_not user.valid?
    assert user.errors.of_kind?(:email, :invalid)
  end

  test "accepts typical email addresses" do
    user = User.new(email: "user@example.com", password: "password123", password_confirmation: "password123")
    assert user.valid?, user.errors.full_messages.join(", ")
  end
end
