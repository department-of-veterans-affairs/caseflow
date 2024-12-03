# frozen_string_literal: true

# This class handles the backfill creation of Automatically established Remand Claims (auto remands)
# and their RequestIssues following the VBMS workflow where the original HLR is completed
# and there are DTA/DOO errors that require a new Remand SC to be created.
class Events::DecisionReviewRemanded
  include RedisMutex::Macro

  class << self
    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def create!(params, headers, payload)
      consumer_event_id = params[:consumer_event_id]
      claim_id = params[:claim_id]
      return if Event.exists_and_is_completed?(consumer_event_id)

      redis = Redis.new(url: Rails.application.secrets.redis_url_cache)

      # exit out if Key is already in Redis Cache
      if redis.exists("RedisMutex:EndProductEstablishment:#{claim_id}")
        fail Caseflow::Error::RedisLockFailed,
             message: "Key RedisMutex:EndProductEstablishment:#{claim_id} is already in the Redis Cache"
      end

      # key => "EndProductEstablishment:reference_id" aka "claim ID" in VBMS
      # Use the consumer_event_id to retrieve/create the Event object
      event = find_or_create_event(consumer_event_id)

      RedisMutex.with_lock("EndProductEstablishment:#{claim_id}", block: 60, expire: 100) do
        ActiveRecord::Base.transaction do
          # Note: some methods will be reused from DecisionReviewCreated
          # Initialize the Parser object that will be passed around as an argument
          # TODO: Use new parser specifically for Remand Events
          parser = Events::DecisionReviewCreated::DecisionReviewCreatedParser.new(headers, payload)

          user = Events::CreateUserOnEvent.handle_user_creation_on_event(event: event, css_id: parser.css_id,
                                                                         station_id: parser.station_id)

          # Create the Veteran. PII Info is stored in the headers
          vet = Events::CreateVeteranOnEvent.handle_veteran_creation_on_event(event: event, parser: parser)

          supplemental_claim = Events::DecisionReviewRemanded::CreateRemandClaimReview.process!(
            event: event,
            parser: parser
          )

          Events::CreateClaimantOnEvent.process!(event: event, parser: parser,
                                                 decision_review: supplemental_claim)

          # NOTE: end_product_establishment & station_id is coming from the payload
          # claim_review will be a supplemental_claim since it is a REMAND
          epe = Events::DecisionReviewCreated::CreateEpEstablishment.process!(parser: parser,
                                                                              claim_review: supplemental_claim,
                                                                              user: user)

          # TODO: create sub class for remand RI?
          Events::DecisionReviewCreated::CreateRequestIssues.process!(
            { event: event, parser: parser, epe: epe,
              decision_review: supplemental_claim }
          )

          # Update the Event after all backfills have completed
          event.update!(completed_at: Time.now.in_time_zone, error: nil, info: { "event_payload" => payload })
        end
      end
    rescue Caseflow::Error::RedisLockFailed => error
      Rails.logger.error("Key RedisMutex:EndProductEstablishment:#{claim_id} is already in the Redis Cache")
      event&.update!(error: error.message)
      raise error
    rescue RedisMutex::LockError => error
      Rails.logger.error("Failed to acquire lock for Claim ID: #{claim_id}! This Event is being"\
                         " processed. Please try again later.")
      event&.update!(error: error.message)
      raise error
    rescue StandardError => error
      Rails.logger.error("#{error.class} : #{error.message}")
      event&.update!(error: "#{error.class} : #{error.message}", info:
        {
          "failed_claim_id" => claim_id,
          "error" => error.message,
          "error_class" => error.class.name,
          "error_backtrace" => error.backtrace
        })
      raise error
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

    # Check if there's already a CF Event that references that Appeals-Consumer EventID
    # We will update the existing Event instead of creating a new one
    def find_or_create_event(consumer_event_id)
      DecisionReviewRemandedEvent.find_or_create_by(reference_id: consumer_event_id)
    end
  end
end
