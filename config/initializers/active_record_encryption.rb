# Keys: ENV > credentials.active_record_encryption > test defaults
module ActiveRecordEncryptionConfig
  DEV_TEST_KEYS = {
    primary_key: "94dafca36a6a2570c2a0acf58dc9be2e19bd1bd1dd1f612aed41a7117f7326dd",
    deterministic_key: "75d5de2aba64506d8a6605bcaec3df75b500e7c2b0105a2b1496adc26b8f0ba0",
    key_derivation_salt: "c4917c17a6de62febb712485db66872cdf6adfac65edf99d99078902663dfd36"
  }.freeze
end

Rails.application.configure do
  creds = Rails.application.credentials.active_record_encryption
  fallback = (Rails.env.local? ? ActiveRecordEncryptionConfig::DEV_TEST_KEYS : {})

  config.active_record.encryption.primary_key =
    ENV["ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY"].presence ||
      creds&.dig(:primary_key) || fallback[:primary_key]

  config.active_record.encryption.deterministic_key =
    ENV["ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY"].presence ||
      creds&.dig(:deterministic_key) || fallback[:deterministic_key]

  config.active_record.encryption.key_derivation_salt =
    ENV["ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT"].presence ||
      creds&.dig(:key_derivation_salt) || fallback[:key_derivation_salt]
end
