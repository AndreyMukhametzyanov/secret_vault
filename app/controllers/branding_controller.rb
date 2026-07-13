class BrandingController < ApplicationController
  before_action :authenticate_user!
  before_action :require_on_prem!
  before_action :require_branding_admin!

  def show
    @site_setting = SiteSetting.current
  end

  def update
    @site_setting = SiteSetting.current
    purge_logo_if_requested!

    if @site_setting.update(branding_params.except(:remove_logo))
      redirect_to branding_path, notice: t("branding.updated")
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def require_on_prem!
    return if SecretVault::Deployment.on_prem?

    redirect_to root_path, alert: t("branding.not_available")
  end

  def require_branding_admin!
    return if current_user.can_manage_branding?

    redirect_to root_path, alert: t("branding.forbidden")
  end

  def branding_params
    params.require(:site_setting).permit(:company_name, :logo, :remove_logo)
  end

  def purge_logo_if_requested!
    return unless ActiveModel::Type::Boolean.new.cast(params.dig(:site_setting, :remove_logo))

    @site_setting.logo.purge
  end
end
