# frozen_string_literal: true

class Fakes::RatingStore < Fakes::PersistentStore
  class << self
    def redis_ns
      "ratings_#{Rails.env}"
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

  def store_rating_profile_record(participant_id, record)
    ratings = fetch_and_inflate(participant_id) || {}
    ratings[:profiles] ||= {}
    ratings[:profiles][record[:profile_date]] = record
    deflate_and_store(participant_id, ratings)
  end
end
