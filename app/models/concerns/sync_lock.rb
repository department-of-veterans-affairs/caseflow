# frozen_string_literal: true

require "redis"

module SyncLock
  extend ActiveSupport::Concern
  LOCK_TIMEOUT = ENV["SYNC_LOCK_MAX_DURATION"]

  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  def hlr_sync_lock
    if decision_review.is_a?(HigherLevelReview) && block_given?
      redis = Redis.new(url: Rails.application.secrets.redis_url_cache)
      lock_key = "hlr_sync_lock:#{end_product_establishment.id}"

      begin
        # create the sync lock with a key, value pair only IF it doesn't already exist
        # and give it an expiration time upon creation.
        sync_lock_acquired = redis.set(lock_key, "lock is set", nx: true, ex: LOCK_TIMEOUT.to_i)
        Rails.logger.info(lock_key + " has been created") if sync_lock_acquired

        fail Caseflow::Error::SyncLockFailed, message: Time.zone.now.to_s unless sync_lock_acquired

        yield
      ensure
        # Delete the lock upon exiting if it was created during this session
        redis.del(lock_key) if sync_lock_acquired
        # if lock was acquired and is later unretrievable, then it was deleted/expired
        if !redis.get(lock_key) && sync_lock_acquired
          Rails.logger.info(lock_key + " has been released")
        end
      end
    elsif block_given?
      yield
    end
  end
  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
end
