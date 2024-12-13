# frozen_string_literal: true

# This class was created with the assumption that the logic for the Complete event would be
#  very similar to that of the Update event, and it will need to be adjusted in the future.
class Events::DecisionReviewCompleted
  include RedisMutex::Macro
  class << self
    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def complete!(params, headers, payload)
      consumer_event_id = params[:consumer_event_id]
      claim_id = params[:claim_id]

      redis = Redis.new(url: Rails.application.secrets.redis_url_cache)

      # exit out if Key is already in Redis Cache
      if redis.exists("RedisMutex:EndProductEstablishment:#{claim_id}")
        fail Caseflow::Error::RedisLockFailed,
             message: "Key RedisMutex:EndProductEstablishment:#{claim_id} is already in the Redis Cache"
      end

      # key => "EndProductEstablishment:reference_id" aka "claim ID"
      # Use the consumer_event_id to retrieve/create the Event object
      event = DecisionReviewCompletedEvent.find_or_create_by(reference_id: consumer_event_id)

      RedisMutex.with_lock("EndProductEstablishment:#{claim_id}", block: 60, expire: 100) do
        ActiveRecord::Base.transaction do
          parser = Events::DecisionReviewCompleted::DecisionReviewCompletedParser.new(headers, payload)

          user = Events::CreateUserOnEvent.handle_user_creation_on_event(
            event: event, css_id: parser.css_id,
            station_id: parser.station_id
          )

          epe = EndProductEstablishment.find_by(
            reference_id: parser.end_product_establishment_reference_id
          )

          review = epe&.source

          Events::DecisionReviewCompleted::CompleteClaimReview.process!(event: event, parser: parser, review: review)
          Events::DecisionReviewCompleted::CompleteEndProductEstablishment.process!(event: event, parser: parser)
          Events::DecisionReviewCompleted::CompleteRequestIssues.process!(event: event, parser: parser, review: review)
          # DecisionIssuesCompleteEvent.new(user: user, review: review, parser: parser, event: event, epe: epe).perform!
          # Update the Event after all operations have completed
          event.update!(completed_at: Time.now.in_time_zone, error: nil, info: { "event_payload" => payload })
        end
      end
    rescue Caseflow::Error::RedisLockFailed => error
      Rails.logger.error("Key RedisMutex:EndProductEstablishment:#{params[:claim_id]} is already in the Redis Cache")
      event&.update!(error: error.message)
      raise error
    rescue RedisMutex::LockError => error
      Rails.logger.error("Failed to acquire lock for Claim ID: #{params[:claim_id]}! This Event is being"\
                         " processed. Please try again later.")
      raise error
    rescue StandardError => error
      Rails.logger.error("#{error.class} : #{error.message}")
      event&.update!(error: "#{error.class} : #{error.message}", info:
        {
          "failed_claim_id" => params[:claim_id],
          "error" => error.message,
          "error_class" => error.class.name,
          "error_backtrace" => error.backtrace,
          "event_payload" => payload
        })
      raise error
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength
  end
end
