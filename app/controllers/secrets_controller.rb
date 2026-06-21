class SecretsController < ApplicationController
  def new
    @secret = Secret.new
  end

  def create
    @secret = Secret.new(
      encrypted_body: secret_params[:body],
      expires_at: 24.hours.from_now
    )

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

    @decrypted_body = @secret.read_and_destroy!
  rescue ActiveRecord::RecordNotFound
    @expired = true
  end

  private

  def secret_params
    params.require(:secret).permit(:body)
  end
end
