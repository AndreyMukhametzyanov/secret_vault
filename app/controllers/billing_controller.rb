class BillingController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_saas_billing!

  def show
    @subscription = current_user.subscription
  end

  def checkout
    unless Yookassa::Configuration.configured?
      redirect_to billing_path, alert: t("billing.not_configured")
      return
    end

    if current_user.pro?
      redirect_to billing_path, notice: t("billing.already_pro")
      return
    end

    unless billing_consents_given?
      redirect_to billing_path, alert: t("legal.consent_required")
      return
    end

    record_billing_consents!

    result = Billing::Checkout.call(user: current_user)
    redirect_to result.confirmation_url, allow_other_host: true
  rescue Billing::Checkout::NotConfigured
    redirect_to billing_path, alert: t("billing.not_configured")
  rescue Yookassa::Client::Error => e
    Rails.logger.error("[Billing::Checkout] #{e.message}")
    redirect_to billing_path, alert: t("billing.checkout_failed")
  end

  def return
    @subscription = current_user.subscription
    render :return
  end

  def cancel_auto_renew
    subscription = current_user.subscription
    if subscription&.pro_entitled?
      subscription.cancel_auto_renew!
      redirect_to billing_path, notice: t("billing.auto_renew_canceled")
    else
      redirect_to billing_path, alert: t("billing.no_active_subscription")
    end
  end

  private

  def ensure_saas_billing!
    return if SecretVault::Deployment.billing_enabled?

    redirect_to root_path, alert: t("billing.not_available_on_prem")
  end

  def billing_consents_given?
    %i[agree_pro_terms agree_auto_renew agree_payment_partner].all? do |key|
      ActiveModel::Type::Boolean.new.cast(params[key])
    end
  end

  def record_billing_consents!
    subscription = current_user.subscription || current_user.create_subscription!(status: "pending")
    now = Time.current
    subscription.update!(
      pro_terms_accepted_at: now,
      auto_renew_consent_at: now,
      payment_partner_consent_at: now
    )
  end
end
