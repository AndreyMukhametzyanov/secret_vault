require "test_helper"

class SecretTest < ActiveSupport::TestCase
  test "requires encrypted body" do
    secret = Secret.new(expires_at: 1.hour.from_now)
    assert_not secret.valid?
    assert secret.errors.added?(:encrypted_body, :blank)
  end

  test "rejects body over size limit" do
    secret = Secret.new(
      encrypted_body: "x" * (Secret::MAX_BODY_BYTES + 1),
      expires_at: 1.hour.from_now
    )
    assert_not secret.valid?
    assert secret.errors[:encrypted_body].any?
  end

  test "read_and_destroy burns secret when max_reads is 1" do
    secret = Secret.create!(encrypted_body: "hello", expires_at: 1.hour.from_now)
    text = secret.read_and_destroy!
    assert_equal "hello", text
    assert_not Secret.exists?(secret.id)
  end
end
