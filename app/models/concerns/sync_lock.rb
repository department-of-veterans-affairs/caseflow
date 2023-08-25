# frozen_string_literal: true

require "redis"

module SyncLock
  extend ActiveSupport::Concern
  LOCK_TIMEOUT = ENV["SYNC_LOCK_MAX_DURATION"]

  def hlr_sync_lock
    if decision_review.is_a?(HigherLevelReview) && block_given?
      redis = Redis.new(url: Rails.application.secrets.redis_url_cache)
      lock_key = "hlr_sync_lock:#{end_product_establishment.id}"
      Rails.logger.info(lock_key + " has been created")

      begin
        # create the sync lock with a key, value pair only IF it doesn't already exist
        # and give it an expiration time upon creation.
        sync_lock_acquired = redis.set(lock_key, "lock is set", nx: true, ex: LOCK_TIMEOUT.to_i)

        fail Caseflow::Error::SyncLockFailed, message: Time.zone.now.to_s unless sync_lock_acquired

        yield
      ensure
        redis.del(lock_key)
        # if lock_key is false then log has been released
        unless redis.get(lock_key)
          Rails.logger.info(lock_key + " has been released")
        end
      end
    elsif block_given?
      yield
    end
  end
end
