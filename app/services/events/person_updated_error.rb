# frozen_string_literal: true

class Events::PersonUpdatedError
  include RedisMutex::Macro

  def initialize(consumer_event_id, participant_id, person_attributes)
    @consumer_event_id = consumer_event_id
    @participant_id = participant_id
    @person_attributes = person_attributes
  end

  def call
    if redis.exists("RedisMutex:#{redis_key}")
      fail Caseflow::Error::RedisLockFailed, message:
        "Key RedisMutex:#{redis_key} is already in the Redis Cache"
    end

    RedisMutex.with_lock(redis_key, block: 60, expire: 60) do
      ActiveRecord::Base.transaction do
        person.assign_attributes(
          person_attributes
        )
        person.save!
      end
    end
  rescue RedisMutex::LockError => error
    Rails.logger.error("LockError occurred: #{error.message}")
  rescue StandardError => error
    Rails.logger.error(error.message)
    event.assign_attributes(error: error.message)
    event.save!
    raise error
  end

  private

  attr_reader :consumer_event_id, :participant_id, :person_attributes

  def redis_key
    "PersonUpdatedError:#{errored_claim_id}"
  end

  def redis
    Redis.new(url: Rails.application.secrets.redis_url_cache)
  end

  def veteran
    Veteran.where(participant_id: participant_id).first
  end

  def person
    Person.where(participant_id: participant_id).first
  end
end
