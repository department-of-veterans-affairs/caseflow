# frozen_string_literal: true

class Events::DecisionReviewCreated
  include RedisMutex::Macro
    # Default options for RedisMutex#with_lock
    # :block  => 1    # Specify in seconds how long you want to wait for the lock to be released.
    #                 # Specify 0 if you need non-blocking sematics and return false immediately. (default: 1)
    # :sleep  => 0.1  # Specify in seconds how long the polling interval should be when :block is given.
    #                 # It is NOT recommended to go below 0.01. (default: 0.1)
    # :expire => 10   # Specify in seconds when the lock should be considered stale when something went wrong
    #                 # with the one who held the lock and failed to unlock. (default: 10)

  class << self
    def create(consumer_event_id, reference_id)
      return if event_exists_and_is_completed?(consumer_event_id)

      RedisMutex.with_lock("EndProductEstablishment:#{reference_id}", block: 60, expire: 100) do
      # key => "EndProductEstablishment:reference_id" aka "claim ID"

        ActiveRecord::Base.transaction do
          # create/save Event to table
          new_event = DecisionReviewCreatedEvent.create!(reference_id: consumer_event_id)

          # TODO: backfill models as needed, set Event.completed_at when finished
          # new_event.update!(completed_at: Time.now)
        end
      end
    rescue RedisMutex::LockError
      Rails.logger.error("Failed to acquire lock for Claim ID: #{reference_id}! This Event is being"\
                         " processed. Please try again later.")
    end

    # Check if there's already a CF Event that references that Appeals-Consumer EventID and
    # was successfully completed
    def event_exists_and_is_completed?(consumer_event_id)
      Event.where(reference_id: consumer_event_id).where.not(completed_at: nil).exists?
    end
  end
end
