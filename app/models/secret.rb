class Secret < ApplicationRecord
  MAX_BODY_BYTES = 8.kilobytes

  encrypts :encrypted_body

  self.primary_key = :id
  before_create :generate_uuid

  validates :encrypted_body, presence: true
  validates :expires_at, presence: true
  validate :encrypted_body_within_size_limit

  scope :active, -> { where("expires_at > ? AND reads_count < max_reads", Time.current) }

  def read_and_destroy!
    return nil if expired?

    decrypted_text = nil

    with_lock do
      self.reads_count += 1
      save!

      decrypted_text = encrypted_body

      destroy! if reads_count >= max_reads
    end

    decrypted_text
  end

  def expired?
    expires_at < Time.current || reads_count >= max_reads
  end

  private

  def generate_uuid
    self.id = SecureRandom.uuid
  end

  def encrypted_body_within_size_limit
    return if encrypted_body.blank?

    if encrypted_body.bytesize > MAX_BODY_BYTES
      errors.add(
        :encrypted_body,
        :too_long,
        max_kb: MAX_BODY_BYTES / 1.kilobyte
      )
    end
  end
end
