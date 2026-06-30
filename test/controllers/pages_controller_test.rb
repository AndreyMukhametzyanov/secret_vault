require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "home landing is public and links to create secret" do
    get root_url
    assert_response :success

    assert_select "h1", text: I18n.t("pages.home.title")
    assert_select "a[href=?]", new_secret_path, text: I18n.t("pages.home.cta_primary")
    assert_select "#how-it-works"
    assert_select "#pricing"
    assert_select "#pricing a[href=?]", new_user_registration_path, text: I18n.t("pages.home.plans.pro_cta")
    assert_select "#security-faq"
    assert_select "#homeFaq .accordion-item", count: 5
  end

  test "legal pages are public with titles and operator notice" do
    {
      privacy_url => I18n.t("pages.privacy.title"),
      terms_url => I18n.t("pages.terms.title"),
      security_url => I18n.t("pages.security.title")
    }.each do |url, heading|
      get url
      assert_response :success
      assert_select "h1", text: heading
      assert_select ".breadcrumb"
      assert_match I18n.t("pages.shared.operator_notice")[0..40], response.body
    end
  end

  test "legal pages include key contact and cross-links in body" do
    get privacy_url
    assert_match "privacy@secretvault.ru", response.body

    get terms_url
    assert_match "support@secretvault.ru", response.body
    assert_match "/privacy", response.body

    get security_url
    assert_match I18n.t("pages.security.honest_notice.title"), response.body
    assert_select ".alert-warning"
  end

  test "layout footer links to legal pages" do
    get root_url
    assert_select "a[href=?]", privacy_path
    assert_select "a[href=?]", terms_path
    assert_select "a[href=?]", security_path
  end

  test "home pro cta links to billing when signed in" do
    user = User.create!(email: "home-pro@example.com", password: "password123")
    sign_in user
    get root_url
    assert_select "#pricing a[href=?]", billing_path, text: I18n.t("pages.home.plans.pro_cta")
  end
end
