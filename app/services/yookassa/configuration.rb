module Yookassa
  class Configuration
    class << self
      def shop_id
        env_or_credential("YOOKASSA_SHOP_ID", %i[yookassa shop_id])
      end

      def secret_key
        env_or_credential("YOOKASSA_SECRET_KEY", %i[yookassa secret_key])
      end

      def configured?
        shop_id.present? && secret_key.present?
      end

      def return_url
        ENV["YOOKASSA_RETURN_URL"].presence ||
          Rails.application.routes.url_helpers.billing_return_url(default_url_options)
      end

      private

      def env_or_credential(env_key, cred_path)
        ENV[env_key].presence || Rails.application.credentials.dig(*cred_path)
      end

      def default_url_options
        Rails.application.config.action_mailer.default_url_options || { host: "localhost", port: 3000 }
      end
    end
  end
end
