# frozen_string_literal: true

class Fakes::RatingStore < Fakes::PersistentStore
  class << self
    def redis_ns
      "ratings_#{Rails.env}"
    end

    def normed_profile_date_key(profile_date)
      (profile_date.try(:to_datetime) ? profile_date.to_datetime.utc : profile_date).iso8601
    end
  end

  def init_store(participant_id)
    ratings = fetch_and_inflate(participant_id) || {}
    ratings[:ratings] ||= []
    ratings[:profiles] ||= {}
    deflate_and_store(participant_id, ratings)
  end

  def store_rating_record(participant_id, record)
    ratings = fetch_and_inflate(participant_id) || {}
    ratings[:ratings] ||= []
    ratings[:ratings] << record
    deflate_and_store(participant_id, ratings)
  end

  def store_rating_profile_record(participant_id, profile_date, record)
    ratings = fetch_and_inflate(participant_id) || {}
    ratings[:profiles] ||= {}
    ratings[:profiles][self.class.normed_profile_date_key(profile_date)] = record
    deflate_and_store(participant_id, ratings)
  end
end
