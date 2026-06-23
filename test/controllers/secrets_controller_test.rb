require "test_helper"

class SecretsControllerTest < ActionDispatch::IntegrationTest
  test "create redirects to success with shareable link" do
    post secrets_path, params: { secret: { body: "top secret" } }
    assert_redirected_to %r{/secrets/.+/success\?token=}
    follow_redirect!
    assert_response :success
    assert_match %r{/secrets/[0-9a-f-]{36}}, response.body
  end

  test "success without creator token returns 404" do
    secret = Secret.create!(encrypted_body: "x", expires_at: 1.hour.from_now)
    secret.assign_creator_token!
    get success_secret_path(secret)
    assert_response :not_found
  end

  test "create rate limit returns 429 after daily quota" do
    ip = "127.0.0.1"
    Secrets::CreateRateLimit::DAILY_LIMIT.times { Secrets::CreateRateLimit.record!(ip) }

    post secrets_path,
      params: { secret: { body: "x" } },
      env: { "REMOTE_ADDR" => ip }

    assert_response :too_many_requests
    assert_match I18n.t("secrets.create.rate_limit_exceeded"), response.body
  end

  test "success returns 404 for expired or burned secret" do
    secret = Secret.create!(encrypted_body: "x", expires_at: 1.hour.ago)
    token = secret.assign_creator_token!
    get success_secret_path(secret, token: token)
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

  test "show with wrong passphrase does not burn secret" do
    secret = Secret.create!(
      encrypted_body: "hidden",
      expires_at: 1.hour.from_now,
      password: "secret"
    )

    get secret_path(secret)
    assert_response :success
    assert_select "input[name=password_attempt]"

    post reveal_secret_path(secret), params: { password_attempt: "wrong" }
    assert_response :unprocessable_entity
    assert_match I18n.t("secrets.show.wrong_password", remaining: 4), response.body
    assert Secret.exists?(secret.id)
    assert_equal 0, secret.reload.reads_count

    post reveal_secret_path(secret), params: { password_attempt: "secret" }
    assert_response :success
    assert_match "hidden", response.body
    assert_not Secret.exists?(secret.id)
  end
end
