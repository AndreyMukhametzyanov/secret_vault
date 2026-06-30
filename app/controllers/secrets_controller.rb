class SecretsController < ApplicationController
  def new
    @secret = Secret.new(
      max_reads: PlanLimits.default_max_reads
    )
    @default_expires_in = PlanLimits.default_expires_in_key
  end

  def create
    unless Secrets::CreateRateLimit.allowed?(client_ip)
      @secret = Secret.new
      flash.now[:alert] = t("secrets.create.rate_limit_exceeded")
      @default_expires_in = PlanLimits.default_expires_in_key
      return render :new, status: :too_many_requests
    end

    @secret = Secret.new(
      encrypted_body: secret_params[:body],
      expires_at: PlanLimits.resolve_expires_at(secret_params[:expires_in]),
      max_reads: PlanLimits.resolve_max_reads(secret_params[:max_reads]),
      creator_user: current_user
    )
    @secret.password = secret_params[:passphrase] if secret_params[:passphrase].present?

    if @secret.save
      creator_token = @secret.assign_creator_token!
      Secrets::CreateRateLimit.record!(client_ip)
      redirect_to success_secret_path(@secret, token: creator_token)
    else
      @default_expires_in = PlanLimits.default_expires_in_key
      render :new, status: :unprocessable_entity
    end
  end

  def success
    @secret = Secret.active.find(params[:id])
    head :not_found and return unless @secret.valid_creator_token?(params[:token])

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
    assign_read_context!(@secret)
  rescue ActiveRecord::RecordNotFound
    @expired = true
  end

  def reveal
    @secret = Secret.active.find_by!(id: params[:id])

    if @secret.authenticate(reveal_params[:password_attempt])
      @decrypted_body = @secret.read_and_destroy!
      assign_read_context!(@secret)
      render :show
    else
      @secret.record_failed_passphrase!
      if @secret.password_locked?
        @expired = true
        render :show, status: :unprocessable_entity
      else
        @requires_password = true
        @wrong_password = true
        @password_attempts_remaining = @secret.password_attempts_remaining
        render :show, status: :unprocessable_entity
      end
    end
  rescue ActiveRecord::RecordNotFound
    @expired = true
    render :show, status: :not_found
  end

  private

  def secret_params
    params.require(:secret).permit(:body, :passphrase, :expires_in, :max_reads)
  end

  def assign_read_context!(secret)
    @max_reads = secret.max_reads
    @reads_count_after = secret.reads_count
  end

  def reveal_params
    params.permit(:password_attempt)
  end
end
