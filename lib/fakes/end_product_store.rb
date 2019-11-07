# frozen_string_literal: true

class Fakes::EndProductStore < Fakes::PersistentStore
  class << self
    def redis_ns
      "end_product_records_#{Rails.env}"
    end
  end

  class Contention < OpenStruct; end

  # we call it a "child" because even though Redis has only key:value pairs,
  # logically the object is a child of an EndProduct
  class ChildStore < Fakes::EndProductStore
    def initialize(parent_key:, child_key:, child:)
      @parent_key = parent_key
      @child_key = child_key.to_s.to_sym
      @child = child
    end

    def create
      children = fetch_children || {}
      children[child_key] = child
      deflate_and_store(parent_key, children)
    end

    def update
      children = fetch_children
      fail "No values for #{parent_key}" unless children

      children[child_key] = child
      deflate_and_store(parent_key, children)
    end

    def remove
      children = fetch_children
      fail "No values for #{parent_key}" unless children

      children.delete(child_key)
      deflate_and_store(parent_key, children)
    end

    private

    attr_reader :parent_key, :child_key, :child

    def fetch_children
      fetch_and_inflate(parent_key)
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

  def update_ep_status(veteran_id, claim_id, new_status)
    eps = fetch_and_inflate(veteran_id)
    eps[claim_id.to_sym][:status_type_code] = new_status
    deflate_and_store(veteran_id, eps)
  end

  # contentions are "children" of End Products but we store by claim_id
  # rather than veteran_id to make look up easier. Dispositions are similar.
  def create_contention(contention)
    contention_child_store(contention).create
  end

  def update_contention(contention)
    contention_child_store(contention).update
  end

  def remove_contention(contention)
    contention_child_store(contention).remove
  end

  def inflated_contentions_for(claim_id)
    children_to_structs(contention_key(claim_id)).map { |struct| Contention.new(struct) }
  end

  def create_disposition(disposition)
    disposition_child_store(disposition).create
  end

  def update_disposition(disposition)
    disposition_child_store(disposition).update
  end

  def remove_disposition(disposition)
    disposition_child_store(disposition).remove
  end

  def inflated_dispositions_for(claim_id)
    children_to_structs(disposition_key(claim_id))
  end

  private

  def contention_key(claim_id)
    "contention_#{claim_id}"
  end

  def disposition_key(claim_id)
    "disposition_#{claim_id}"
  end

  def contention_child_store(contention)
    claim_id = contention.claim_id
    ChildStore.new(parent_key: contention_key(claim_id), child: contention, child_key: contention.id)
  end

  def disposition_child_store(disposition)
    claim_id = disposition.claim_id
    ChildStore.new(parent_key: disposition_key(claim_id), child: disposition, child_key: disposition.contention_id)
  end

  def children_to_structs(key)
    (fetch_and_inflate(key) || {}).values.map { |hash| OpenStruct.new(hash[:table]) }
  end
end
