require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "pro? is false until subscription is wired" do
    user = User.new
    assert_not user.pro?
  end
end
