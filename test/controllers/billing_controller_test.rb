require "test_helper"

class BillingControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "billing@example.com", password: "password123")
  end

  test "show requires authentication" do
    get billing_path
    assert_redirected_to new_user_session_path
  end

  test "show when yookassa is not configured" do
    sign_in @user
    stub_singleton(Yookassa::Configuration, :configured?, false) do
      get billing_path
      assert_response :success
      assert_match I18n.t("billing.not_configured"), response.body
    end
  end

  test "checkout redirects to confirmation url" do
    sign_in @user
    result = Billing::Checkout::Result.new(
      confirmation_url: "https://yookassa.test/confirm",
      payment_id: "pay-99"
    )

    stub_singleton(Yookassa::Configuration, :configured?, true) do
      stub_singleton(Billing::Checkout, :call, result) do
        post billing_checkout_path, params: {
          agree_pro_terms: "1",
          agree_auto_renew: "1",
          agree_payment_partner: "1"
        }
        assert_redirected_to "https://yookassa.test/confirm"
      end
    end
  end

  test "checkout without consents is rejected" do
    sign_in @user

    stub_singleton(Yookassa::Configuration, :configured?, true) do
      post billing_checkout_path
      assert_redirected_to billing_path
      follow_redirect!
      assert_match I18n.t("legal.consent_required"), response.body
    end
  end

  test "checkout records billing consents on subscription" do
    sign_in @user
    result = Billing::Checkout::Result.new(
      confirmation_url: "https://yookassa.test/confirm",
      payment_id: "pay-99"
    )

    stub_singleton(Yookassa::Configuration, :configured?, true) do
      stub_singleton(Billing::Checkout, :call, result) do
        post billing_checkout_path, params: {
          agree_pro_terms: "1",
          agree_auto_renew: "1",
          agree_payment_partner: "1"
        }
      end
    end

    sub = @user.reload.subscription
    assert sub.pro_terms_accepted_at.present?
    assert sub.auto_renew_consent_at.present?
    assert sub.payment_partner_consent_at.present?
  end

  test "cancel auto renew for active pro" do
    sign_in @user
    @user.create_subscription!(
      status: "active",
      current_period_ends_at: 1.month.from_now,
      auto_renew: true
    )

    patch billing_cancel_auto_renew_path
    assert_redirected_to billing_path
    assert_not @user.subscription.reload.auto_renew?
  end
end
