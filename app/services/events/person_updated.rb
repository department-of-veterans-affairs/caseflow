# frozen_string_literal: true

class Events::PersonUpdated
  include RedisMutex::Macro

  def initialize(consumer_event_id, participant_id, is_veteran, person_attributes)
    @consumer_event_id = consumer_event_id
    @participant_id = participant_id
    @person_attributes = person_attributes
    @is_veteran = is_veteran
  end

  def call
    if redis.exists("RedisMutex:#{redis_key}")
      fail Caseflow::Error::RedisLockFailed, message: "Key RedisMutex:#{redis_key} is already in the Redis Cache"
    end

    RedisMutex.with_lock(redis_key, block: 60, expire: 100) do
      ActiveRecord::Base.transaction do
        update_person
        update_veteran if is_veteran
      end
    end
  rescue RedisMutex::LockError => error
    Rails.logger.error("LockError occurred: #{error.message}")
  rescue StandardError => error
    Rails.logger.error(error.message)
    raise error
  end

  private

  attr_reader :consumer_event_id, :participant_id, :person_attributes, :is_veteran

  def update_person
    person.assign_attributes(
      person_attributes.as_json.without("date_of_death", "file_number")
    )
    person.save!
  end

  def update_veteran
    if veteran.present?
      veteran.assign_attributes(
        person_attributes.as_json.without("email_address")
      )
      veteran.save!
    end
  end

  def redis_key
    "PersonUpdated:#{consumer_event_id}"
  end

  def redis
    Redis.new(url: Rails.application.secrets.redis_url_cache)
  end

  def veteran
    @veteran ||= Veteran.where(participant_id: participant_id).first
  end

  def person
    @person ||= Person.where(participant_id: participant_id).first
  end
end
