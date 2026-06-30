class SecretsController < ApplicationController
  before_action :set_plan_limits, only: [ :new, :create ]
  def new
    @secret = Secret.new(max_reads: @plan_limits.default_max_reads)
    @default_expires_in = @plan_limits.default_expires_in_key
  end

  def create
    unless Secrets::CreateRateLimit.allowed?(client_ip)
      @secret = Secret.new
      flash.now[:alert] = t("secrets.create.rate_limit_exceeded")
      @default_expires_in = @plan_limits.default_expires_in_key
      return render :new, status: :too_many_requests
    end

    @secret = Secret.new(
      encrypted_body: secret_params[:body],
      expires_at: @plan_limits.resolve_expires_at(secret_params[:expires_in]),
      max_reads: @plan_limits.resolve_max_reads(secret_params[:max_reads]),
      creator_user: current_user
    )
    apply_passphrase!(@secret, secret_params[:passphrase])

    if @secret.save
      creator_token = @secret.assign_creator_token!
      Secrets::CreateRateLimit.record!(client_ip)
      redirect_to success_secret_path(@secret, token: creator_token)
    else
      @default_expires_in = secret_params[:expires_in].presence || @plan_limits.default_expires_in_key
      @selected_max_reads = secret_params[:max_reads]
      @submitted_body = secret_params[:body]
      @submitted_passphrase = secret_params[:passphrase]
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

  def set_plan_limits
    @plan_limits = plan_limits
  end

  def secret_params
    params.require(:secret).permit(:body, :passphrase, :expires_in, :max_reads)
  end

  def apply_passphrase!(secret, passphrase)
    return if passphrase.blank?
    return unless @plan_limits.passphrase_enabled?

    secret.password = passphrase
  end

  def assign_read_context!(secret)
    @max_reads = secret.max_reads
    @reads_count_after = secret.reads_count
  end

  def reveal_params
    params.permit(:password_attempt)
  end
end
