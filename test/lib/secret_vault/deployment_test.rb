require "test_helper"

class SecretVault::DeploymentTest < ActiveSupport::TestCase
  test "defaults to saas mode" do
    with_deployment_mode(nil) do
      assert SecretVault::Deployment.saas?
      assert SecretVault::Deployment.billing_enabled?
      assert_not SecretVault::Deployment.licensed_pro?
    end
  end

  test "on_prem disables billing and enables licensed pro" do
    with_deployment_mode("on_prem") do
      assert SecretVault::Deployment.on_prem?
      assert_not SecretVault::Deployment.billing_enabled?
      assert SecretVault::Deployment.licensed_pro?
    end
  end

  private

  def with_deployment_mode(mode)
    previous = ENV["DEPLOYMENT_MODE"]
    if mode.nil?
      ENV.delete("DEPLOYMENT_MODE")
    else
      ENV["DEPLOYMENT_MODE"] = mode
    end
    yield
  ensure
    if previous.nil?
      ENV.delete("DEPLOYMENT_MODE")
    else
      ENV["DEPLOYMENT_MODE"] = previous
    end
  end
end
