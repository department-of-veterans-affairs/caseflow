# frozen_string_literal: true

class Events::PersonUpdatedError
  include RedisMutex::Macro

  def initialize(event_id, participant_id, error_message)
    @event_id = event_id
    @participant_id = participant_id
    @error_message = error_message
  end

  def call
    if redis.exists("RedisMutex:#{redis_key}")
      fail Caseflow::Error::RedisLockFailed, message: "Key RedisMutex:#{redis_key} is already in the Redis Cache"
    end

    exists = false

    RedisMutex.with_lock(redis_key, block: 60, expire: 100) do
      ActiveRecord::Base.transaction do
        exists = event_exists?

        update_event
      end
    end

    exists ? :updated : :created
  rescue RedisMutex::LockError => error
    Rails.logger.error("LockError occurred: #{error.message}")
    raise Caseflow::Error::RedisLockFailed
  rescue StandardError => error
    Rails.logger.error(error.message)
    event.update!(error: error.message)
    raise error
  end

  private

  attr_reader :event_id, :participant_id, :error_message

  def update_event
    event.update!(
      error: error_message,
      info: { "errored_claim_id" => participant_id },
      errored_claim_id: participant_id
    )
  end

  def redis_key
    "PersonUpdatedError:#{event_id}"
  end

  def redis
    Redis.new(url: Rails.application.secrets.redis_url_cache)
  end

  def event_exists?
    event.persisted?
  end

  def event
    @event ||= PersonUpdatedErrorEvent.find_or_initialize_by(reference_id: event_id)
  end
end
