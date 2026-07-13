require "test_helper"

class Billing::ProcessPaymentNotificationTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(email: "pay@example.com", password: "password123")
    @payment = @user.billing_payments.create!(
      yookassa_payment_id: "yk-payment-1",
      amount_cents: Billing::ProPlan.amount_cents,
      currency: "RUB",
      status: "pending",
      purpose: "pro_initial"
    )
  end

  test "payment.succeeded activates pro and stores payment method" do
    remote = {
      "id" => "yk-payment-1",
      "status" => "succeeded",
      "metadata" => { "user_id" => @user.id.to_s },
      "payment_method" => { "id" => "pm-1", "saved" => true }
    }

    Billing::ProcessPaymentNotification.call(
      event: "payment.succeeded",
      payment_object: remote,
      client: noop_client
    )

    @payment.reload
    @user.subscription.reload

    assert @payment.succeeded?
    assert_equal "pm-1", @user.subscription.yookassa_payment_method_id
    assert @user.pro?
  end

  test "payment.succeeded is idempotent" do
    remote = {
      "id" => "yk-payment-1",
      "status" => "succeeded",
      "payment_method" => { "id" => "pm-1", "saved" => true }
    }

    2.times do
      Billing::ProcessPaymentNotification.call(
        event: "payment.succeeded",
        payment_object: remote,
        client: noop_client
      )
    end

    assert_equal 1, @user.billing_payments.where(status: "succeeded").count
    ends_at = @user.subscription.current_period_ends_at
    Billing::ProcessPaymentNotification.call(
      event: "payment.succeeded",
      payment_object: remote,
      client: noop_client
    )
    assert_in_delta ends_at.to_i, @user.subscription.reload.current_period_ends_at.to_i, 2
  end

  private

  def noop_client
    @noop_client ||= Class.new do
      def fetch_payment(_id)
        raise "should not fetch when configured? is false"
      end
    end.new
  end
end
