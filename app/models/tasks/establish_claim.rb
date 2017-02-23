class EstablishClaim < Task
  include CachedAttributes

  # Methods pull from VACOLS if not cached.
  # Prefixed with `cached_` to avoid assuming they were updated
  def cached_decision_type
    appeal.decision_type
  end
  cache_attribute :cached_decision_type

  def cached_veteran_name
    appeal.veteran_name
  end
  cache_attribute :cached_veteran_name

  def initial_action
    "show"
  end
end
