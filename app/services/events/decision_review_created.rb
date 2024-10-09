# frozen_string_literal: true

class Events::DecisionReviewCreated
  include RedisMutex::Macro
  include Events::DecisionReviewCreated::UpdateVacolsOnOptin
  # Default options for RedisMutex#with_lock
  # :block  => 1    # Specify in seconds how long you want to wait for the lock to be released.
  #                 # Specify 0 if you need non-blocking sematics and return false immediately. (default: 1)
  # :sleep  => 0.1  # Specify in seconds how long the polling interval should be when :block is given.
  #                 # It is NOT recommended to go below 0.01. (default: 0.1)
  # :expire => 10   # Specify in seconds when the lock should be considered stale when something went wrong
  #                 # with the one who held the lock and failed to unlock. (default: 10)

  class << self
    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Lint/UselessAssignment
    def create!(params, headers, payload)
      consumer_event_id = params[:consumer_event_id]
      reference_id = params[:reference_id]
      return if Event.exists_and_is_completed?(consumer_event_id)

      redis = Redis.new(url: Rails.application.secrets.redis_url_cache)

      # exit out if Key is already in Redis Cache
      if redis.exists("RedisMutex:EndProductEstablishment:#{reference_id}")
        fail Caseflow::Error::RedisLockFailed,
             message: "Key RedisMutex:EndProductEstablishment:#{reference_id} is already in the Redis Cache"
      end

      RedisMutex.with_lock("EndProductEstablishment:#{reference_id}", block: 60, expire: 100) do
        # key => "EndProductEstablishment:reference_id" aka "claim ID"
        # Use the consumer_event_id to retrieve/create the Event object
        event = find_or_create_event(consumer_event_id)

        ActiveRecord::Base.transaction do
          # Initialize the Parser object that will be passed around as an argument
          parser = Events::DecisionReviewCreated::DecisionReviewCreatedParser.new(headers, payload)

          # NOTE: createdByStation == station_id, createdByUsername == css_id
          user = Events::CreateUserOnEvent.handle_user_creation_on_event(event: event, css_id: parser.css_id,
                                                                         station_id: parser.station_id)

          # Create the Veteran. PII Info is stored in the headers
          vet = Events::CreateVeteranOnEvent.handle_veteran_creation_on_event(event: event, parser: parser)

          # Note Create Claim Review, parsed schema info passed through claim_review and intake
          decision_review = Events::DecisionReviewCreated::CreateClaimReview.process!(parser: parser)

          # NOTE: Create the Claimant, parsed schema info passed through vbms_claimant
          Events::CreateClaimantOnEvent.process!(event: event, parser: parser,
                                                 decision_review: decision_review)

          # NOTE: event, user, and veteran need to be before this call.
          Events::DecisionReviewCreated::CreateIntake.process!(
            { event: event, user: user, veteran: vet,
              parser: parser, decision_review: decision_review }
          )

          # NOTE: end_product_establishment & station_id is coming from the payload
          # claim_review can either be a higher_level_revew or supplemental_claim
          epe = Events::DecisionReviewCreated::CreateEpEstablishment.process!(parser: parser,
                                                                              claim_review: decision_review,
                                                                              user: user)

          # NOTE: 'epe' arg is the obj created as a result of the CreateEpEstablishment service class
          Events::DecisionReviewCreated::CreateRequestIssues.process!(
            { event: event, parser: parser, epe: epe,
              decision_review: decision_review }
          )

          # NOTE: decision_review arg can either be a HLR or SC object. process! will only run if
          # decision_review.legacy_opt_in_approved is true
          Events::DecisionReviewCreated::UpdateVacolsOnOptin.process!(decision_review: decision_review)

          # Update the Event after all backfills have completed
          event.update!(completed_at: Time.now.in_time_zone, error: nil, info: {})
        end
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
      Rails.logger.error("#{error.class} : #{error.message}")
      event = Event.find_by(reference_id: consumer_event_id)
      event&.update!(error: "#{error.class} : #{error.message}", info: { "failed_claim_id" => reference_id })
      raise error
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength, Lint/UselessAssignment

    # Check if there's already a CF Event that references that Appeals-Consumer EventID
    # We will update the existing Event instead of creating a new one
    def find_or_create_event(consumer_event_id)
      DecisionReviewCreatedEvent.find_or_create_by(reference_id: consumer_event_id)
    end
  end
end
