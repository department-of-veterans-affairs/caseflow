# frozen_string_literal: true

class Fakes::PersistentStore
  class << self
    def redis_ns
      "persistent_store_#{Rails.env}"
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

    json_str ? decode_json(json_str) : nil
  end

  def deflate_and_store(key, payload)
    self.class.cache_store.set(key, payload.to_json)
  end

  private

  # we copied the ActiveSupport::JSON date parsing private method, since we want:
  # * to symbolize keys,
  # * all Times cast to UTC as DateTime objects.
  def decode_json(json_str)
    convert_dates_from(JSON.parse(json_str, symbolize_names: true))
  end

  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/CyclomaticComplexity
  def convert_dates_from(data)
    case data
    when nil
      nil
    when ActiveSupport::JSON::DATE_REGEX
      begin
        Date.parse(data)
      rescue ArgumentError
        data
      end
    when ActiveSupport::JSON::DATETIME_REGEX
      begin
        Time.zone.parse(data).utc.to_datetime
      rescue ArgumentError
        data
      end
    when Array
      data.map! { |d| convert_dates_from(d) }
    when Hash
      data.each do |key, value|
        data[key] = convert_dates_from(value)
      end
    else
      data
    end
  end
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/CyclomaticComplexity
end
