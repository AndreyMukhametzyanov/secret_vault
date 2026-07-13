require "test_helper"

class OnPremBillingTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "onprem@example.com", password: "password123")
  end

  test "billing is blocked in on_prem mode" do
    sign_in @user
    with_deployment_mode("on_prem") do
      get billing_path
      assert_redirected_to root_path
    end
  end

  test "yookassa webhook returns not found in on_prem mode" do
    with_deployment_mode("on_prem") do
      post webhooks_yookassa_path, params: { event: "payment.succeeded", object: { id: "x" } }, as: :json
      assert_response :not_found
    end
  end
end
