class ApplicationController < ActionController::Base
  helper PagesHelper
  helper_method :plan_limits

  before_action :configure_permitted_parameters, if: :devise_controller?

  private

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :email ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :email ])
  end

  def client_ip
    request.remote_ip
  end

  def plan_limits
    PlanLimits
  end
end
