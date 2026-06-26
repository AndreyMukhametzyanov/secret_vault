module PagesHelper
  LEGAL_PROSE_TAGS = %w[strong em ul ol li a p br].freeze
  LEGAL_PROSE_ATTRS = %w[href target rel].freeze

  def show_nav_create_secret?
    !(controller_name == "secrets" && %w[new create].include?(action_name))
  end

  def legal_page_t(key, **options)
    t("pages.#{action_name}.#{key}", **options)
  end

  def legal_page_sections
    Array(t("pages.#{action_name}.sections"))
  end

  def legal_page_checklist
    Array(t("pages.#{action_name}.checklist"))
  end

  def legal_prose_html(html)
    sanitize(html, tags: LEGAL_PROSE_TAGS, attributes: LEGAL_PROSE_ATTRS)
  end

  def legal_page_date_label
    scope = "pages.#{action_name}"
    return t("#{scope}.last_updated") if I18n.exists?("#{scope}.last_updated")
    return t("#{scope}.updated") if I18n.exists?("#{scope}.updated")

    nil
  end
end
