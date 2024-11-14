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
        create_event
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

  attr_reader :event, :consumer_event_id, :participant_id, :person_attributes, :is_veteran

  def create_event
    @event = Events::PersonUpdatedEvent.create(
      reference_id: consumer_event_id
    )
  end

  def update_person
    before_attributes = person.attributes

    person.assign_attributes(
      person_attributes.as_json.without("date_of_death", "file_number")
    )
    person.save!

    create_person_event(before_attributes, person.attributes)
  end

  def update_veteran
    if veteran.present?
      before_attributes = veteran.attributes
      veteran.assign_attributes(
        person_attributes.as_json.without("email_address")
      )
      veteran.save!

      create_veteran_event(before_attributes, veteran.attributes)
    end
  end

  def info_attributes(attributes)
    {
      "id": attributes["id"],
      "created_at": attributes["created_at"],
      "updated_at": attributes["updated_at"],
      "participant_id": attributes["participant_id"],
      "date_of_birth": attributes["date_of_birth"].to_s,
      "first_name": attributes["first_name"],
      "last_name": attributes["last_name"],
      "middle_name": attributes["middle_name"],
      "name_suffix": attributes["name_suffix"],
      "email_address": attributes["email_address"],
      "ssn": attributes["ssn"]
    }
  end

  def create_person_event(before_attributes, after_attributes)
    event.event_records.create(
      evented_record_type: "Person",
      evented_record_id: before_attributes["id"],
      info: {
        "before_date": {
          **info_attributes(before_attributes)
        },
        "record_date": {
          **info_attributes(after_attributes)
        }
      }
    )
  end

  def create_veteran_event(before_attributes, after_attributes)
    event.event_records.create(
      evented_record_type: "Veteran",
      evented_record_id: before_attributes["id"],
      info: {
        "before_date": {
          **info_attributes(before_attributes)
        },
        "record_date": {
          **info_attributes(after_attributes)
        }
      }
    )
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
