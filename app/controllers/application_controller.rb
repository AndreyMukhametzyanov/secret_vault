class ApplicationController < ActionController::Base
  helper PagesHelper
  helper_method :plan_limits

  private

  def client_ip
    request.remote_ip
  end

  def plan_limits
    PlanLimits
  end
end
