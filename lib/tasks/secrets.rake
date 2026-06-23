namespace :secrets do
  desc "Delete secrets past expires_at"
  task expire_stale: :environment do
    deleted = Secrets::ExpireStaleJob.perform_now
    puts deleted.positive? ? "Deleted #{deleted} expired secret(s)" : "No expired secrets"
  end
end
