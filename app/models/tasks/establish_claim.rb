class EstablishClaim < Task
  include CachedAttributes

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
