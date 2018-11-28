class Fakes::EndProductStore
  REDIS_NS ||= "end_product_records_#{Rails.env}"

  def self.cache_store
    @cache_store ||= begin
      redis_conn = Redis.new(url: Rails.application.secrets.redis_url_cache)
      Redis::Namespace.new(REDIS_NS, redis: redis_conn)
    end
  end

  def clear!
    self.class.cache_store.redis.keys("#{REDIS_NS}:*").each do |k|
      self.class.cache_store.redis.del(k)
    end
  end

  def store_end_product_record(key, value)
    # puts "end product store #{key} => #{value.to_json}"
    subkey = value[:benefit_claim_id]
    existing_value = fetch_and_inflate(key)
    if existing_value
      existing_value[subkey] = value
      deflate_and_store(key, existing_value)
    else
      deflate_and_store(key, subkey => value)
    end
  end

  def fetch_and_inflate(key)
    json_str = self.class.cache_store.get(key)
    # puts "found #{key} -> #{json_str.pretty_inspect}"
    json_str ? JSON.parse(json_str, symbolize_names: true) : nil
  end

  def deflate_and_store(key, value)
    # puts "store #{key} => #{value.pretty_inspect}"
    self.class.cache_store.set(key, value.to_json)
  end
end
