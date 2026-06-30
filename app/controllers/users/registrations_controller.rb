module Users
  class RegistrationsController < Devise::RegistrationsController
    def create
      unless registration_consents_given?
        build_resource(sign_up_params)
        resource.errors.add(:base, I18n.t("legal.consent_required"))
        clean_up_passwords resource
        set_minimum_password_length
        respond_with resource
        return
      end

      super

      return unless resource.persisted?

      now = Time.current
      resource.update!(terms_accepted_at: now, privacy_accepted_at: now)
    end

    private

    def registration_consents_given?
      boolean_param(params[:agree_terms]) && boolean_param(params[:agree_privacy])
    end

    def boolean_param(value)
      ActiveModel::Type::Boolean.new.cast(value)
    end
  end
end
