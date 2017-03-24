class EstablishClaim < Task
  include CachedAttributes

  has_one :claim_establishment, foreign_key: :task_id

  cache_attribute :cached_decision_type do
    appeal.decision_type
  end

  cache_attribute :cached_veteran_name do
    appeal.veteran_name
  end
end
