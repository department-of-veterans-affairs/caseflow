class CacheManager
  class NoSuchBucket < StandardError; end

  BUCKETS = {
    bgs: [

    ],
    vbms: [

    ],
    vacols: [
      "#{Rails.env}_list_of_judges_from_vacols",
      "#{Rails.env}_list_of_judges_from_vacols_with_name_and_id",
      "#{Rails.env}_list_of_attorneys_from_vacols",
      "#{Rails.env}_list_of_hearing_coordinators_from_vacols"
    ],
    caseflow: [

    ]
  }.freeze

  def self.cache_store
    @cache_store ||= begin
      redis_conn = Redis.new(url: Rails.application.secrets.redis_url_cache)
    end
  end

  def all_cache_keys
    # skip some persistent key patterns because they are maintained separately.
    keys = []
    self.class.cache_store.scan_each do |key|
      next if key.match?(/^(feature_toggle|functions):/)
      keys << key
    end
    keys
  end

  def clear(bucket)
    key_names = BUCKETS[bucket.to_sym]
    fail NoSuchBucket, bucket unless key_names

    key_names.each do |key|
      Rails.cache.delete(key)
    end
  end
end
