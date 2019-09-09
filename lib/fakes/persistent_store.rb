# frozen_string_literal: true

class Fakes::PersistentStore
  REDIS_NS ||= "persistent_store_#{Rails.env}"

  class << self
    def redis_ns
      REDIS_NS
    end

    def cache_store
      @cache_store ||= begin
        redis_conn = Redis.new(url: Rails.application.secrets.redis_url_cache)
        Redis::Namespace.new(redis_ns, redis: redis_conn)
      end
    end

    def all_keys
      cache_store.redis.keys("#{redis_ns}:*")
    end

    def clear!
      all_keys.each do |key|
        cache_store.redis.del(key)
      end
    end
  end

  def all_keys
    self.class.all_keys
  end

  def clear!
    self.class.clear!
  end

  def delete(key)
    self.class.cache_store.redis.del(key)
  end

  def fetch_and_inflate(key)
    json_str = self.class.cache_store.get(key)
    return if json_str.nil? || json_str == "null"

    json_str ? JSON.parse(json_str, symbolize_names: true) : nil
  end

  def deflate_and_store(key, payload)
    self.class.cache_store.set(key, payload.to_json)
  end
end
