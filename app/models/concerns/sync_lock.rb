# frozen_string_literal: true

require "redis"

module SyncLock
  extend ActiveSupport::Concern
  LOCK_TIMEOUT = ENV["SYNC_LOCK_MAX_DURATION"]

  def hlr_sync_lock
    if decision_review.is_a?(HigherLevelReview) && block_given?
      redis = Redis.new(url: Rails.application.secrets.redis_url_cache)
      lock_key = "hlr_sync_lock:#{end_product_establishment.id}"

      begin
        # create the sync lock with a key, value pair only IF it doesn't already exist
        # and give it an expiration time upon creation
        sync_lock_acquired = redis.set(lock_key, "lock is set", nx: true, ex: LOCK_TIMEOUT.to_i)

        fail Caseflow::Error::SyncLockFailed, message: Time.zone.now.to_s unless sync_lock_acquired

        # set expire as another failsafe
        redis.expire(lock_key, LOCK_TIMEOUT.to_i)
        yield
      ensure
        redis.del(lock_key)
      end
    elsif block_given?
      yield
    end
  end
end
