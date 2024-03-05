# frozen_string_literal: true

class Events::DecisionReviewCreated
  include RedisMutex::Macro
  include Events::DecisionReviewCreated::UpdateVacolsOnOptin
  include Events::DecisionReviewCreated::CreateIntake
  # Default options for RedisMutex#with_lock
  # :block  => 1    # Specify in seconds how long you want to wait for the lock to be released.
  #                 # Specify 0 if you need non-blocking sematics and return false immediately. (default: 1)
  # :sleep  => 0.1  # Specify in seconds how long the polling interval should be when :block is given.
  #                 # It is NOT recommended to go below 0.01. (default: 0.1)
  # :expire => 10   # Specify in seconds when the lock should be considered stale when something went wrong
  #                 # with the one who held the lock and failed to unlock. (default: 10)

  class << self
    def create!(consumer_event_id, reference_id)
      return if event_exists_and_is_completed?(consumer_event_id)

      redis = Redis.new(url: Rails.application.secrets.redis_url_cache)

      # exit out if Key is already in Redis Cache
      if redis.exists("RedisMutex:EndProductEstablishment:#{reference_id}")
        fail Caseflow::Error::RedisLockFailed, message: "Key RedisMutex:EndProductEstablishment:#{reference_id} is already in the Redis Cache"
      end

      RedisMutex.with_lock("EndProductEstablishment:#{reference_id}", block: 60, expire: 100) do
        # key => "EndProductEstablishment:reference_id" aka "claim ID"
        # Use the consumer_event_id to retrieve/create the Event object
        event = find_or_create_event(consumer_event_id)

        # ActiveRecord::Base.transaction do
          # TODO: backfill models as needed, set Event.completed_at when finished

          # Note: createdByStation == station_id, createdByUsername == css_id
          # Events::CreateUserOnEvent.handle_user_creation_on_event(event, css_id, station_id)

          # Create the Veteran. PII Info is stored in the headers
          # vet = Events::CreateVeteranOnEvent.handle_veteran_creation_on_event(event, headers, vbms_veteran)

          # Note: decision_review arg can either be a HLR or SC object. process! will only run if
          # decision_review.legacy_opt_in_approved is true
          # Events::DecisionReviewCreate::UpdateVacolsOnOptin.process!(decision_review)
          # event.update!(completed_at: Time.now, error: nil)
        # end
      end
    rescue Caseflow::Error::RedisLockFailed => error
      Rails.logger.error("Key RedisMutex:EndProductEstablishment:#{reference_id} is already in the Redis Cache")
      event = Event.find_by(reference_id: consumer_event_id)
      event&.update!(error: error.message)
      raise error
    rescue RedisMutex::LockError => error
      Rails.logger.error("Failed to acquire lock for Claim ID: #{reference_id}! This Event is being"\
                         " processed. Please try again later.")
    rescue StandardError => error
      Rails.logger.error(error.message)
      event = Event.find_by(reference_id: consumer_event_id)
      event&.update!(error: error.message, info: { "failed_claim_id" => reference_id })
      raise error
    end

    # Check if there's already a CF Event that references that Appeals-Consumer EventID and
    # was successfully completed
    def event_exists_and_is_completed?(consumer_event_id)
      Event.where(reference_id: consumer_event_id).where.not(completed_at: nil).exists?
    end

    # Check if there's already a CF Event that references that Appeals-Consumer EventID
    # We will update the existing Event instead of creating a new one
    def find_or_create_event(consumer_event_id)
      DecisionReviewCreatedEvent.find_or_create_by(reference_id: consumer_event_id)
    end

  end
end
