require "test_helper"

class OnPremUserProTest < ActiveSupport::TestCase
  test "user is pro without subscription when licensed on_prem" do
    user = User.create!(email: "lic@example.com", password: "password123")
    assert_not user.pro?

    with_deployment_mode("on_prem") do
      assert user.pro?
    end
  end
end
