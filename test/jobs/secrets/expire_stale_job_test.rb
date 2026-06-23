require "test_helper"

class Secrets::ExpireStaleJobTest < ActiveJob::TestCase
  test "deletes secrets past expires_at" do
    stale = Secret.create!(encrypted_body: "old", expires_at: 1.hour.ago)
    fresh = Secret.create!(encrypted_body: "new", expires_at: 1.hour.from_now)

    Secrets::ExpireStaleJob.perform_now

    assert_not Secret.exists?(stale.id)
    assert Secret.exists?(fresh.id)
  end
end
