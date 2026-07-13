require "test_helper"

class Webhooks::YookassaControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    @user = User.create!(email: "hook@example.com", password: "password123")
    @user.billing_payments.create!(
      yookassa_payment_id: "hook-pay-1",
      amount_cents: Billing::ProPlan.amount_cents,
      currency: "RUB",
      status: "pending",
      purpose: "pro_initial"
    )
  end

  test "accepts payment notification and enqueues job" do
    payload = {
      type: "notification",
      event: "payment.succeeded",
      object: {
        id: "hook-pay-1",
        status: "succeeded",
        payment_method: { id: "pm-hook", saved: true }
      }
    }

    assert_enqueued_with(job: Billing::ProcessYookassaNotificationJob) do
      post "/webhooks/yookassa",
        params: payload.to_json,
        headers: { "CONTENT_TYPE" => "application/json" }
    end

    assert_response :ok
  end

  test "rejects invalid json" do
    post "/webhooks/yookassa", params: "not-json", headers: { "CONTENT_TYPE" => "application/json" }
    assert_response :bad_request
  end
end
