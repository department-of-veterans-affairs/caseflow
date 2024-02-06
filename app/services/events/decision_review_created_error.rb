# frozen_string_literal: true

class Events::DecisionReviewCreatedError
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
      event = find_by_consumer_event_id_or_create(consumer_event_id)
      RedisMutex.with_lock("EndProductEstablishment:#{errored_claim_id}", block: 60, expire: 100) do
        ActiveRecord::Base.transaction do
          event&.update!(error: error_message, info: { "errored_claim_id" => errored_claim_id })
        end
      end
    rescue RedisMutex::LockError
      Rails.logger.error("Failed to acquire lock for Claim ID: #{errored_claim_id}! This Event is being"\
                        " processed. Please try again later.")
    rescue StandardError => error
      Rails.logger.error(error.message)
      event&.update!(error: error.message)
      raise error
    end

    # check if consumer_event_id Event.reference_id exist if not Create DecisionReviewCreated Event
    def find_by_consumer_event_id_or_create(consumer_event_id)
      Event.find_by(reference_id: consumer_event_id) ||
        DecisionReviewCreatedEvent.create!(reference_id: consumer_event_id)
    end
  end
end
