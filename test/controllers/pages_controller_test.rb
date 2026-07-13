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
    assert_match "privacy@example.com", response.body

    get terms_url
    assert_match "support@example.com", response.body
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

  test "on_prem marketing page is public on saas" do
    get on_prem_url
    assert_response :success
    assert_select "h1", text: I18n.t("pages.on_prem.title")
    assert_match SecretVault::Deployment.sales_contact_email, response.body
  end

  test "on_prem page redirects when already on_prem deployment" do
    with_deployment_mode("on_prem") do
      get on_prem_url
      assert_redirected_to root_path
    end
  end

  test "footer links to on_prem on saas" do
    get root_url
    assert_select "a[href=?]", on_prem_path, text: I18n.t("layouts.application.footer.on_prem")
  end

  test "home hides pricing on on_prem deployment" do
    with_deployment_mode("on_prem") do
      get root_url
      assert_response :success
      assert_select "#pricing", count: 0
      assert_match I18n.t("pages.home.lead_on_prem"), response.body
      assert_no_match I18n.t("pages.home.lead"), response.body
    end
  end

  test "saas navbar ignores stored on-prem branding" do
    SiteSetting.current.update!(company_name: "ACME Corp")

    with_deployment_mode("saas") do
      get root_url
      assert_response :success
      assert_no_match "ACME Corp", response.body
    end
  end
end
