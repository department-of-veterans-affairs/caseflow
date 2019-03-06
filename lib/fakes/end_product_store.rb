# frozen_string_literal: true

class Fakes::EndProductStore
  REDIS_NS ||= "end_product_records_#{Rails.env}"

  def self.cache_store
    @cache_store ||= begin
      redis_conn = Redis.new(url: Rails.application.secrets.redis_url_cache)
      Redis::Namespace.new(REDIS_NS, redis: redis_conn)
    end
  end

  def self.all_keys
    cache_store.redis.keys("#{REDIS_NS}:*")
  end

  def clear!
    self.class.all_keys.each do |k|
      self.class.cache_store.redis.del(k)
    end
  end

  def store_end_product_record(veteran_id, end_product)
    claim_id = end_product[:benefit_claim_id]
    existing_eps = fetch_and_inflate(veteran_id)
    if existing_eps
      existing_eps[claim_id] = end_product
      deflate_and_store(veteran_id, existing_eps)
    else
      deflate_and_store(veteran_id, claim_id => end_product)
    end
  end

  def fetch_and_inflate(veteran_id)
    json_str = self.class.cache_store.get(veteran_id)
    json_str ? JSON.parse(json_str, symbolize_names: true) : nil
  end

  def deflate_and_store(veteran_id, end_products)
    self.class.cache_store.set(veteran_id, end_products.to_json)
  end
end
