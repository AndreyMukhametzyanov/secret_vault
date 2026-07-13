module ApplicationHelper
  def form_control_class(object, attribute, base_class: "form-control")
    [ base_class, ("is-invalid" if object.errors[attribute].any?) ].compact.join(" ")
  end

  def saas_billing?
    SecretVault::Deployment.billing_enabled?
  end

  def on_prem_deployment?
    SecretVault::Deployment.on_prem?
  end

  def site_setting
    @site_setting ||= SiteSetting.current
  end
end
