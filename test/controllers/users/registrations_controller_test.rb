require "test_helper"

class Users::RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "registration without consents does not create user" do
    assert_no_difference "User.count" do
      post user_registration_path, params: {
        user: { email: "new@example.com", password: "password123", password_confirmation: "password123" }
      }
    end

    assert_response :unprocessable_entity
    assert_match I18n.t("legal.consent_required"), response.body
  end

  test "registration with consents stores acceptance timestamps" do
    post user_registration_path, params: {
      user: { email: "consented@example.com", password: "password123", password_confirmation: "password123" },
      agree_terms: "1",
      agree_privacy: "1"
    }

    user = User.find_by(email: "consented@example.com")
    assert user
    assert user.terms_accepted_at.present?
    assert user.privacy_accepted_at.present?
  end

  test "duplicate email does not reveal that address is registered" do
    User.create!(email: "taken@example.com", password: "password123")

    assert_no_difference "User.count" do
      post user_registration_path, params: {
        user: { email: "taken@example.com", password: "password123", password_confirmation: "password123" },
        agree_terms: "1",
        agree_privacy: "1"
      }
    end

    assert_response :unprocessable_entity
    assert_no_match(/уже занят/i, response.body)
    assert_no_match(/already been taken/i, response.body)
    assert_match I18n.t("devise.registrations.email_unavailable"), response.body
  end
end
