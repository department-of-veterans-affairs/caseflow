# frozen_string_literal: true

# DecisionReviewUpdatedError Service. This handles the service error payload from the appeals-consumer.
# Payload requires event_id, errored_claim_id, and the error_message within the request
# This service also uses the RedisMutex.with_lock to make sure parallel transactions related to the claim_id
# does not make database changes at the same time.
class Events::DecisionReviewUpdatedError
  # Using macro-style definition. The locking scope will be TheClass#method and only one method can run at any
  # given time.
  include RedisMutex::Macro

  # Default options for RedisMutex#with_lock
  # :block  => 1    # Specify in seconds how long you want to wait for the lock to be released.
  #                 # Specify 0 if you need non-blocking sematics and return false immediately. (default: 1)
  # :sleep  => 0.1  # Specify in seconds how long the polling interval should be when :block is given.
  #                 # It is NOT recommended to go below 0.01. (default: 0.1)
  # :expire => 10   # Specify in seconds when the lock should be considered stale when something went wrong
  #                 # with the one who held the lock and failed to unlock. (default: 10)
  class << self
    def handle_service_error(consumer_event_id, errored_claim_id, error_message)
      # check if consumer_event_id Event.reference_id exist if not Create DecisionReviewCreated Event
      event = DecisionReviewCreatedEvent.find_by(reference_id: consumer_event_id)

      redis = Redis.new(url: Rails.application.secrets.redis_url_cache)

      if redis.exists("RedisMutex:EndProductEstablishment:#{errored_claim_id}")
        fail Caseflow::Error::RedisLockFailed, message: "Key RedisMutex:EndProductEstablishment:#{errored_claim_id}
         is already in the Redis Cache"
      end

      RedisMutex.with_lock("EndProductEstablishment:#{errored_claim_id}", block: 60, expire: 100) do
        ActiveRecord::Base.transaction do
          event&.update!(error: error_message, info: { "errored_claim_id" => errored_claim_id })
        end
      end
    rescue RedisMutex::LockError => error
      Rails.logger.error("LockError occurred: #{error.message}")
    rescue StandardError => error
      Rails.logger.error(error.message)
      event&.update!(error: error.message)
      raise error
    end
  end
end
