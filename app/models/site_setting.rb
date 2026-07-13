class SiteSetting < ApplicationRecord
  ALLOWED_LOGO_TYPES = %w[image/png image/jpeg image/webp image/svg+xml].freeze
  MAX_LOGO_SIZE = 2.megabytes

  has_one_attached :logo

  validates :company_name, length: { maximum: 120 }, allow_blank: true
  validate :logo_format_and_size, if: -> { logo.attached? }

  def self.current
    first_or_create!
  end

  private

  def logo_format_and_size
    blob = logo.blob
    return if blob.blank?

    unless ALLOWED_LOGO_TYPES.include?(blob.content_type)
      errors.add(:logo, :invalid_type)
      return
    end

    errors.add(:logo, :too_large) if blob.byte_size > MAX_LOGO_SIZE
  end
end
