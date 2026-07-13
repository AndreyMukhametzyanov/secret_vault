class PagesController < ApplicationController
  def home
  end

  def privacy
  end

  def terms
  end

  def security
  end

  def on_prem
    return redirect_to root_path if SecretVault::Deployment.on_prem?

    @contact_email = SecretVault::Deployment.sales_contact_email
  end
end
