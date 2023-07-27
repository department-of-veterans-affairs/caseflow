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
        sync_lock_acquired = redis.setnx(lock_key, true)

        fail Caseflow::Error::SyncLockFailed, message: "#{Time.zone.now}" unless sync_lock_acquired

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
