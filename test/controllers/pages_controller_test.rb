require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "home landing is public and links to create secret" do
    get root_url
    assert_response :success

    assert_select "h1", text: I18n.t("pages.home.title")
    assert_select "a[href=?]", new_secret_path, text: I18n.t("pages.home.cta_primary")
    assert_select "#how-it-works"
    assert_select "#pricing"
    assert_select "#security-faq"
    assert_select "#homeFaq .accordion-item", count: 5
  end

  test "legal pages are public" do
    get privacy_url
    assert_response :success

    get terms_url
    assert_response :success

    get security_url
    assert_response :success
  end
end
