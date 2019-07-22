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

  def delete(key)
    self.class.cache_store.redis.del(key)
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

  def deflate_and_store(key, payload)
    self.class.cache_store.set(key, payload.to_json)
  end

  def update_ep_status(veteran_id, claim_id, new_status)
    eps = fetch_and_inflate(veteran_id)
    eps[claim_id.to_sym][:status_type_code] = new_status
    deflate_and_store(veteran_id, eps)
  end

  # contentions are "children" of End Products but we store by claim_id
  # rather than veteran_id to make look up easier.
  def create_contention(contention)
    claim_id = contention.claim_id
    contentions = contentions_for(claim_id) || {}
    contentions[contention.id.to_s] = contention
    deflate_and_store(contention_key(claim_id), contentions)
  end

  def update_contention(contention)
    claim_id = contention.claim_id
    contentions = contentions_for(claim_id) or fail "No contentions for claim_id #{claim_id}"
    contentions[contention.id.to_s] = contention
    deflate_and_store(contention_key(claim_id), contentions)
  end

  def remove_contention(contention)
    claim_id = contention.claim_id
    contentions = contentions_for(claim_id) or fail "No contentions for claim_id #{claim_id}"
    contentions.delete(contention.id.to_s)
    deflate_and_store(contention_key(claim_id), contentions)
  end

  def contention_key(claim_id)
    "contention_#{claim_id}"
  end

  def contentions_for(claim_id)
    fetch_and_inflate(contention_key(claim_id))
  end

  def inflated_contentions_for(claim_id)
    contentions_for(claim_id).values.map { |cont| OpenStruct.new(cont[:table]) }.each { |cont| cont.id = cont.id.to_i }
  end
end
