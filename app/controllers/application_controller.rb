class ApplicationController < ActionController::Base
  private

  def client_ip
    request.remote_ip
  end
end
