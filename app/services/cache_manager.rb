# frozen_string_literal: true

class CacheManager
  class NoSuchBucket < StandardError; end

  BUCKETS = {
    bgs: [
      "bgs_can_access_*",
      "SupplementalClaim-*-ratings-*-cached-*",
      "HigherLevelReview-*-ratings-*-cached-*",
      "Appeal-*-ratings-*-cached-*"
    ],
    vbms: [],
    vacols: [
      "#{Rails.env}_list_of_judges_from_vacols",
      "#{Rails.env}_list_of_judges_from_vacols_with_name_and_id",
      "#{Rails.env}_list_of_attorneys_from_vacols",
      "#{Rails.env}_list_of_hearing_coordinators_from_vacols"
    ],
    caseflow: [
      "EstablishClaim-*-cached-*",
      "LegacyAppeal-*-cached-*",
      "LegacyHearing-*-cached-*",
      "JudgeSchedulePeriod-*-cached-*",
      "SchedulePeriod-*-cached-*",
      "RoSchedulePeriod-*-cached-*",
      "RampElectionIntake-*-cached-*",
      "IntakeStats-last-calculated-timestamp"
    ]
  }.freeze

  def self.rails_cache
    @rails_cache ||= ActiveSupport::Cache.lookup_store(Rails.configuration.cache_store)
  end

  # NOTE that development and test envs currently do not use the Redis store, so this only applies
  # to production environments (AWS)
  def self.cache_store
    @cache_store ||= begin
      redis_conn = Redis.new(url: Rails.application.secrets.redis_url_cache)
      Redis::Namespace.new("cache", redis: redis_conn)
    end
  end

  def all_cache_keys
    self.class.cache_store.keys
  end

  def clear(bucket)
    key_names = BUCKETS[bucket.to_sym]
    fail NoSuchBucket, bucket unless key_names

    rails_cache = self.class.rails_cache

    key_names.each do |key|
      if key.match?(/[\*\[\?]/)
        rails_cache.delete_matched(key)
      else
        rails_cache.delete(key)
      end
    end
  end
end
