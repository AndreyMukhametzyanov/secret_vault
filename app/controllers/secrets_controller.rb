class SecretsController < ApplicationController
  def new
    @secret = Secret.new
  end

  def create
    @secret = Secret.new(
      encrypted_body: secret_params[:body],
      expires_at: 24.hours.from_now
    )
    @secret.password = secret_params[:passphrase] if secret_params[:passphrase].present?

    if @secret.save
      redirect_to success_secret_path(@secret)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def success
    @secret = Secret.active.find(params[:id])
    @shareable_url = secret_url(@secret)
  rescue ActiveRecord::RecordNotFound
    head :not_found
  end

  def show
    @secret = Secret.active.find_by!(id: params[:id])

    if @secret.password_protected?
      @requires_password = true
      return
    end

    @decrypted_body = @secret.read_and_destroy!
  rescue ActiveRecord::RecordNotFound
    @expired = true
  end

  def reveal
    @secret = Secret.active.find_by!(id: params[:id])

    if @secret.authenticate(reveal_params[:password_attempt])
      @decrypted_body = @secret.read_and_destroy!
      render :show
    else
      @secret.record_failed_passphrase!
      @requires_password = true
      @wrong_password = true
      render :show, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    @expired = true
    render :show, status: :not_found
  end

  private

  def secret_params
    params.require(:secret).permit(:body, :passphrase)
  end

  def reveal_params
    params.permit(:password_attempt)
  end
end
