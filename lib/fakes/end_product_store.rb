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

  def fetch_and_inflate(key)
    json_str = self.class.cache_store.get(key)
    json_str ? JSON.parse(json_str, symbolize_names: true) : nil
  end

  def update_ep_status(veteran_id, claim_id, new_status)
    eps = fetch_and_inflate(veteran_id)
    eps[claim_id.to_sym][:status_type_code] = new_status
    deflate_and_store(veteran_id, eps)
  end

  # contentions are "children" of End Products but we store by claim_id
  # rather than veteran_id to make look up easier. Dispositions are similar.
  def create_contention(contention)
    claim_id = contention.claim_id
    create_ep_child(contention, contention_key(claim_id), :id)
  end

  def update_contention(contention)
    claim_id = contention.claim_id
    update_ep_child(contention, contention_key(claim_id), :id)
  end

  def remove_contention(contention)
    claim_id = contention.claim_id
    remove_ep_child(contention, contention_key(claim_id), :id)
  end

  def contention_key(claim_id)
    "contention_#{claim_id}"
  end

  def inflated_contentions_for(claim_id)
    children_to_structs(contention_key(claim_id)).each do |cont|
      cont.id = cont.id.to_i
    end
  end

  def create_disposition(disposition)
    claim_id = disposition.claim_id
    create_ep_child(disposition, disposition_key(claim_id), :contention_id)
  end

  def update_disposition(disposition)
    claim_id = disposition.claim_id
    update_ep_child(disposition, disposition_key(claim_id), :contention_id)
  end

  def remove_disposition(disposition)
    claim_id = disposition.claim_id
    remove_ep_child(disposition, disposition_key(claim_id), :contention_id)
  end

  def disposition_key(claim_id)
    "disposition_#{claim_id}"
  end

  def inflated_dispositions_for(claim_id)
    children_to_structs(disposition_key(claim_id)).each do |disp|
      disp.contention_id = disp.contention_id.to_i
    end
  end

  private

  def deflate_and_store(key, payload)
    self.class.cache_store.set(key, payload.to_json)
  end

  def children_to_structs(key)
    children_for(key).values.map { |hash| OpenStruct.new(hash[:table]) }
  end

  def children_for(key)
    fetch_and_inflate(key)
  end

  def create_ep_child(child, key, id_attr)
    children = children_for(key) || {}
    children[child[id_attr]] = child
    deflate_and_store(key, children)
  end

  def update_ep_child(child, key, id_attr)
    children = children_for(key)
    fail "No values for #{key}" unless children

    children[child[id_attr].to_s] = child
    deflate_and_store(key, children)
  end

  def remove_ep_child(child, key, id_attr)
    children = children_for(key)
    fail "No values for #{key}" unless children

    children.delete(child[id_attr].to_s)
    deflate_and_store(key, children)
  end
end
