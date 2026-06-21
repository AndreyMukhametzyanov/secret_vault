require "test_helper"

class SecretsControllerTest < ActionDispatch::IntegrationTest
  test "create redirects to success with shareable link" do
    post secrets_path, params: { secret: { body: "top secret" } }
    assert_redirected_to %r{/secrets/.+/success}
    follow_redirect!
    assert_response :success
    assert_match %r{/secrets/[0-9a-f-]{36}}, response.body
  end

  test "success returns 404 for expired or burned secret" do
    secret = Secret.create!(encrypted_body: "x", expires_at: 1.hour.ago)
    get success_secret_path(secret)
    assert_response :not_found
  end

  test "show burns secret on first view" do
    secret = Secret.create!(encrypted_body: "once", expires_at: 1.hour.from_now)
    get secret_path(secret)
    assert_response :success
    assert_match "once", response.body

    get secret_path(secret)
    assert_response :success
    assert_match I18n.t("secrets.show.expired_title"), response.body
  end
end
