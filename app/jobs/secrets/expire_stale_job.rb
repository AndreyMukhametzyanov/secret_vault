module Secrets
  class ExpireStaleJob < ApplicationJob
    queue_as :default

    def perform
      Secret.where("expires_at < ?", Time.current).delete_all
    end  
  end
end
